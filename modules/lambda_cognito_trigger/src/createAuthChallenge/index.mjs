// createAuthChallenge
import {
  CognitoIdentityProviderClient,
  AdminUpdateUserAttributesCommand,
} from "@aws-sdk/client-cognito-identity-provider";
import crypto from "node:crypto";

const idp = new CognitoIdentityProviderClient({});

function hmacOtp(username, otp, secret) {
  return crypto.createHmac("sha256", secret).update(`${username}:${otp}`).digest("hex");
}

export const handler = async (event) => {
  const meta = event.request?.clientMetadata || {};
  const flow = (meta.flow || 'otp').toLowerCase();

  if (flow === 'social') {
    // purely cosmetic/diagnostic; verifyAuthChallenge will do the heavy lift
    event.response.publicChallengeParameters = { medium: 'social', provider: meta.provider || '' };
    event.response.privateChallengeParameters = {};
    event.response.challengeMetadata = 'SOCIAL';
  } else {
    // Generate OTP
    const otp = String(Math.floor(100000 + Math.random() * 900000)); // 6-digit OTP
    const OTP_SECRET = process.env.OTP_SECRET || 'default-secret-change-in-production';
    const { userName, userPoolId } = event;
    
    // Create HMAC hash
    const otpHash = hmacOtp(userName, otp, OTP_SECRET);
    
    // Set expiration (5 minutes from now)
    const exp = Math.floor(Date.now() / 1000) + 300;
    
    // Store hash and expiration in user attributes
    try {
      await idp.send(new AdminUpdateUserAttributesCommand({
        UserPoolId: userPoolId,
        Username: userName,
        UserAttributes: [
          { Name: "custom:otp_hash", Value: otpHash },
          { Name: "custom:otp_exp", Value: String(exp) },
        ],
      }));
      
      // Log OTP for testing (REMOVE IN PRODUCTION!)
      console.log(`Generated OTP: ${otp} for user ${userName} (expires in 5 minutes)`);
    } catch (error) {
      console.error('Error storing OTP:', error);
    }
    
    // default OTP wording
    event.response.publicChallengeParameters = { medium: 'email' };
    event.response.privateChallengeParameters = { otp }; // Not sent to client
    event.response.challengeMetadata = 'OTP';
  }

  return event;
};
