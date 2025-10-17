// VerifyAuthChallenge (Node.js 18)
// OTP flow: HMAC(OTP) + exp check against Cognito custom attributes
// Social flow: verify upstream token → ensure shadow user → accept
import {
  CognitoIdentityProviderClient,
  AdminGetUserCommand,
  AdminCreateUserCommand,
  AdminUpdateUserAttributesCommand,
} from "@aws-sdk/client-cognito-identity-provider";
import { jwtVerify, createRemoteJWKSet } from "jose";
import crypto from "node:crypto";

const idp = new CognitoIdentityProviderClient({});

// ===== helpers ==============================================================
const isJwt = (t) => typeof t === "string" && t.split(".").length === 3;

const JWKS = {
  google: createRemoteJWKSet(new URL("https://www.googleapis.com/oauth2/v3/certs")),
  apple: createRemoteJWKSet(new URL("https://appleid.apple.com/auth/keys")),
  facebook: createRemoteJWKSet(new URL("https://www.facebook.com/.well-known/oauth/openid/jwks/")),
};

function hmacOtp(username, otp, secret) {
  return crypto.createHmac("sha256", secret).update(`${username}:${otp}`).digest("hex");
}

function timingSafeEq(a, b) {
  // Compare as Buffers to avoid subtle timing leaks
  try {
    const ba = Buffer.from(a, "hex");
    const bb = Buffer.from(b, "hex");
    if (ba.length !== bb.length) return false;
    return crypto.timingSafeEqual(ba, bb);
  } catch {
    return false;
  }
}

async function verifyGoogle(idToken) {
  const audience = process.env.GOOGLE_AUDIENCE;
  if (!audience) throw new Error("GOOGLE_AUDIENCE not set");
  const { payload } = await jwtVerify(idToken, JWKS.google, {
    issuer: ["https://accounts.google.com", "accounts.google.com"],
    audience,
  });
  return {
    provider: "google",
    sub: String(payload.sub),
    email: payload.email || undefined,
    emailVerified: !!payload.email_verified,
  };
}

async function verifyApple(idToken) {
  const audience = process.env.APPLE_AUDIENCE;
  if (!audience) throw new Error("APPLE_AUDIENCE not set");
  const { payload } = await jwtVerify(idToken, JWKS.apple, {
    issuer: "https://appleid.apple.com",
    audience,
  });
  return {
    provider: "apple",
    sub: String(payload.sub),
    email: payload.email,
    emailVerified: payload.email_verified === "true" || payload.email_verified === true,
  };
}

async function verifyFacebook(token) {
  // A) OIDC id_token (JWT)
  if (isJwt(token)) {
    const audience = process.env.FACEBOOK_AUDIENCE || process.env.FACEBOOK_APP_ID;
    if (!audience) throw new Error("FACEBOOK_AUDIENCE or FACEBOOK_APP_ID not set");
    const { payload } = await jwtVerify(token, JWKS.facebook, {
      issuer: ["https://www.facebook.com", "https://facebook.com"],
      audience,
    });
    return {
      provider: "facebook",
      sub: String(payload.sub),
      email: payload.email,
      emailVerified: undefined,
    };
  }

  // B) Graph access_token → /debug_token
  const appId = process.env.FACEBOOK_APP_ID;
  const appSecret = process.env.FACEBOOK_APP_SECRET;
  if (!appId || !appSecret) throw new Error("FACEBOOK_APP_ID/SECRET not set");

  const appToken = `${appId}|${appSecret}`;
  const url = new URL("https://graph.facebook.com/debug_token");
  url.searchParams.set("input_token", token);
  url.searchParams.set("access_token", appToken);

  const res = await fetch(url.toString());
  if (!res.ok) throw new Error(`facebook debug_token failed: ${res.status}`);
  const data = await res.json();
  if (!data?.data?.is_valid) throw new Error("facebook access_token invalid");

  return { provider: "facebook", sub: String(data.data.user_id) };
}

async function ensureUser(provider, sub, email, poolId) {
  const username = `${provider}:${sub}`;
  try {
    await idp.send(new AdminGetUserCommand({ UserPoolId: poolId, Username: username }));
    if (email) {
      await idp.send(new AdminUpdateUserAttributesCommand({
        UserPoolId: poolId,
        Username: username,
        UserAttributes: [
          { Name: "email", Value: email },
          { Name: "email_verified", Value: "true" },
        ],
      }));
    }
    return username;
  } catch {
    const attrs = [];
    if (email) {
      attrs.push({ Name: "email", Value: email });
      attrs.push({ Name: "email_verified", Value: "true" });
    }
    await idp.send(new AdminCreateUserCommand({
      UserPoolId: poolId,
      Username: username,
      MessageAction: "SUPPRESS",
      UserAttributes: attrs,
    }));
    return username;
  }
}

// ===== main ================================================================
export const handler = async (event) => {
  const { userPoolId, userName } = event;
  const meta = event.request.clientMetadata || {};
  const flow = meta.flow || "otp";

  // === OTP (HMAC) =========================================================
  if (flow === "otp") {
    const now = Math.floor(Date.now() / 1000);
    const answer = String(event.request.challengeAnswer || "").trim();
    const OTP_SECRET = process.env.OTP_SECRET;
    if (!OTP_SECRET) {
      // Fail explicitly rather than silently approving
      throw new Error("OTP_SECRET not configured");
    }

    const res = await idp.send(
      new AdminGetUserCommand({ UserPoolId: userPoolId, Username: userName })
    );
    const map = Object.fromEntries((res.UserAttributes || []).map(a => [a.Name, a.Value]));
    const exp = Number(map["custom:otp_exp"] || 0);
    const storedHash = map["custom:otp_hash"] || "";

    // Recompute HMAC on the Lambda side
    const providedHash = hmacOtp(userName, answer, OTP_SECRET);

    const notExpired = now <= exp && exp > 0;
    const hashOk = storedHash && timingSafeEq(storedHash, providedHash);

    const ok = notExpired && hashOk;

    // Cleanup on success (and mark email verified to smooth future flows)
    if (ok) {
      try {
        await idp.send(new AdminUpdateUserAttributesCommand({
          UserPoolId: userPoolId,
          Username: userName,
          UserAttributes: [
            { Name: "custom:otp", Value: "" },         // in case it exists
            { Name: "custom:otp_hash", Value: "" },
            { Name: "custom:otp_exp", Value: "" },
            { Name: "email_verified", Value: "true" },
          ],
        }));
      } catch {}
    }

    event.response.answerCorrect = !!ok;
    return event;
  }

  // === SOCIAL =============================================================
  if (flow === "social") {
    const provider = (meta.provider || "").toLowerCase();
    const idToken = meta.idToken || "";
    const accessToken = meta.accessToken || "";
    if (!provider || !["google","apple","facebook"].includes(provider)) {
      throw new Error("unsupported provider");
    }
    if (!idToken && !accessToken) throw new Error("idToken or accessToken required");

    // 1) Verify upstream token
    let v;
    if (provider === "google") v = await verifyGoogle(idToken);
    else if (provider === "apple") v = await verifyApple(idToken);
    else v = await verifyFacebook(idToken || accessToken);

    // 2) Ensure user exists
    const canonicalUsername = await ensureUser(provider, v.sub, v.email, userPoolId);

    // 3) Strong guard: the flow must start with USERNAME = `${provider}:${sub}`
    //    (constant-time-ish compare)
    if (canonicalUsername.length !== userName.length ||
        !crypto.timingSafeEqual(Buffer.from(canonicalUsername), Buffer.from(userName))) {
      event.response.answerCorrect = false;
      return event;
    }

    // Optional: sync email_verified from upstream
    if (v.email && v.emailVerified) {
      try {
        await idp.send(new AdminUpdateUserAttributesCommand({
          UserPoolId: userPoolId,
          Username: canonicalUsername,
          UserAttributes: [
            { Name: "email", Value: v.email },
            { Name: "email_verified", Value: "true" },
          ],
        }));
      } catch {}
    }

    event.response.answerCorrect = true;
    return event;
  }

  // Unknown flow → fail
  event.response.answerCorrect = false;
  return event;
};
