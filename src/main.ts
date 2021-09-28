import * as core from '@actions/core';
import * as httpm from '@actions/http-client';
import * as io from '@actions/io';
import * as installer from './installer';
import cp from 'child_process';

export async function run() {
  try {
    let versionSpec = await semver(core.getInput('buildtools-version'));

    core.info(`Setup buildtools version spec '${versionSpec}'`);

    const installDir = await installer.getBuildtools(versionSpec);

    core.addPath(installDir);
    core.info('Added buildtools to the path');

    // output the version actually being used
    let buildToolsPath = await io.which('build');
    let buildToolsVersion = (
      cp.execSync(`${buildToolsPath} --version`) || ''
    ).toString();
    core.info(buildToolsVersion);
  } catch (error) {
    core.setFailed(error.message);
  }
}

export async function addBinToPath(): Promise<boolean> {
  let added = false;
  let g = await io.which('build');
  core.debug(`which build :${g}:`);
  if (!g) {
    core.debug('build not in the path');
    return added;
  }

  return added;
}

//
// Convert the version into semver for semver matching
// v1.13.1 => 1.13.1
// 1.13.1 => 1.13.1
// 1.13 => 1.13.0
// 1.10beta1 => 1.10.0-beta1, 1.10rc1 => 1.10.0-rc1
// 1.8.5beta1 => 1.8.5-beta1, 1.8.5rc1 => 1.8.5-rc1
async function semver(version: string): Promise<string> {
  if (version == '' || version == 'latest') {
    version = await resolveLatestVersion();
  } else {
    version = version.replace('beta', '-beta').replace('rc', '-rc');
  }
  version = version.replace('v', '');
  let parts = version.split('-');

  let verPart: string = parts[0];
  let prereleasePart = parts.length > 1 ? `-${parts[1]}` : '';

  let verParts: string[] = verPart.split('.');
  if (verParts.length == 2) {
    verPart += '.0';
  }

  return `${verPart}${prereleasePart}`;
}

async function resolveLatestVersion(): Promise<string> {
  let _http = new httpm.HttpClient('build-tools setup');
  let res: httpm.HttpClientResponse = await _http.get(
    'https://api.github.com/repos/buildtool/build-tools/releases/latest'
  );
  core.debug(`Got response from Github`);

  if (res.message.statusCode != 200) {
    throw new Error('failed to get latest version Github');
  }
  let body: string = await res.readBody();
  let obj: any = JSON.parse(body);
  let version = obj.name;
  core.info(`Got buildtools version latest => ${version}`);
  return version;
}
