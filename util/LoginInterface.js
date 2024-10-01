function LoginInterface(loginModule) {
  if (typeof loginModule.login !== 'function') {
    throw new Error('Login modules must have a login method');
  }
  if (typeof loginModule.getPage !== 'function') {
    throw new Error('Login modules must have a getPage method');
  }
  if (typeof loginModule.close !== 'function') {
    throw new Error('Login modules must have a close method');
  }
  return loginModule;
}

export default LoginInterface;
