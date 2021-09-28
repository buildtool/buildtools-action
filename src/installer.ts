import * as tc from '@actions/tool-cache';
import * as core from '@actions/core';
import os from 'os';
import {getArch, getPlatform} from './system';

export interface IBuildtoolsVersionFile {
  downloadUrl: string;
  os: string;
  arch: string;
}

export async function getBuildtools(versionSpec: string) {
  let downloadPath = '';
  let info: IBuildtoolsVersionFile = await resolveDist(versionSpec);
  try {
    core.info(`Attempting to download '${info.downloadUrl}'`);
    downloadPath = await installBuildtoolsVersion(info);
  } catch (err) {
    throw new Error(`Failed to download version ${versionSpec}: ${err}`);
  }

  return downloadPath;
}

async function resolveDist(version: string) {
  let info: IBuildtoolsVersionFile = <IBuildtoolsVersionFile>{};
  info.os = getPlatform();
  info.arch = getArch();
  info.downloadUrl = `https://github.com/buildtool/build-tools/releases/download/v${version}/build-tools_${version}_${info.os}_${info.arch}.tar.gz`;
  return info;
}

async function installBuildtoolsVersion(
  info: IBuildtoolsVersionFile
): Promise<string> {
  core.info(`Acquiring buildtools from ${info.downloadUrl}`);
  const downloadPath = await tc.downloadTool(info.downloadUrl, undefined);

  core.info('Extracting Buildtools...');
  let extPath = await extractBuildtoolsArchive(downloadPath);
  core.info(`Successfully extracted buildtools to ${extPath}`);

  return extPath;
}

export async function extractBuildtoolsArchive(
  archivePath: string
): Promise<string> {
  const platform = os.platform();
  let extPath: string;

  if (platform === 'win32') {
    extPath = await tc.extractZip(archivePath);
  } else {
    extPath = await tc.extractTar(archivePath);
  }

  return extPath;
}
