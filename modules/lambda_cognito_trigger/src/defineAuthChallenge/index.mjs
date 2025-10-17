// defineAuthChallenge
export const handler = async (event) => {
  const session = event.request?.session || [];

  if (session.length === 0) {
    // First time: ask for a CUSTOM_CHALLENGE (OTP or social)
    event.response.issueTokens = false;
    event.response.failAuthentication = false;
    event.response.challengeName = 'CUSTOM_CHALLENGE';
    return event;
  }

  // If the last challenge was answered correctly → issue tokens
  if (session[session.length - 1].challengeResult === true) {
    event.response.issueTokens = true;
    event.response.failAuthentication = false;
    return event;
  }

  // Too many attempts → fail
  if (session.length >= 3) {
    event.response.issueTokens = false;
    event.response.failAuthentication = true;
    return event;
  }

  // Otherwise, ask for the same challenge again
  event.response.issueTokens = false;
  event.response.failAuthentication = false;
  event.response.challengeName = 'CUSTOM_CHALLENGE';
  return event;
};
