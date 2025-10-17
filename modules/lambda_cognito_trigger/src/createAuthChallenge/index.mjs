// createAuthChallenge
export const handler = async (event) => {
  const meta = event.request?.clientMetadata || {};
  const flow = (meta.flow || 'otp').toLowerCase();

  if (flow === 'social') {
    // purely cosmetic/diagnostic; verifyAuthChallenge will do the heavy lift
    event.response.publicChallengeParameters = { medium: 'social', provider: meta.provider || '' };
    event.response.privateChallengeParameters = {};
    event.response.challengeMetadata = 'SOCIAL';
  } else {
    // default OTP wording
    event.response.publicChallengeParameters = { medium: 'email' };
    event.response.privateChallengeParameters = {};
    event.response.challengeMetadata = 'OTP';
  }

  return event;
};
