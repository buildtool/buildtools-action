import {semver} from '../src/main';

test('simple versions', async () => {
  expect(await semver('v1.13.1')).toBe('1.13.1');
  expect(await semver('1.13.1')).toBe('1.13.1');
  expect(await semver('1.13')).toBe('1.13.0');
});

test('pre-release versions', async () => {
  expect(await semver('1.10beta1')).toBe('1.10.0-beta1');
  expect(await semver('1.10-beta1')).toBe('1.10.0-beta1');
  expect(await semver('1.8.5rc1')).toBe('1.8.5-rc1');
  expect(await semver('0.2.0-beta.1')).toBe('0.2.0-beta.1');
});
