#!/usr/bin/env node

const { exec } = require('child_process');
const path = require('path');
const yargs = require('yargs');
const dotenv = require('dotenv');

dotenv.config(); // Load environment variables from the package user's own .env file
dotenv.config({ path: `.env.local`, override: true }); // also load user's .env.local and override clashing values from .env

const dockerComposePaths = [path.join(__dirname, '../docker-compose.yml')];
// On Linux (including WSL), Docker doesn't always provide host.docker.internal, so add a small override.
// On Docker Desktop (macOS/Windows), host.docker.internal is built-in and should not be overridden.
if (process.platform === 'linux') {
  dockerComposePaths.push(path.join(__dirname, '../docker-compose.linux.yml'));
}

const envVariables = {
  APP_NAME: process.env.APP_NAME || 'new-website',
  LOCAL_DOMAIN: process.env.LOCAL_DOMAIN || 'localhost',
  DB_ROOT_PASSWORD: process.env.DB_ROOT_PASSWORD || 'db_root_password',
  DB_NAME: process.env.DB_NAME || 'wordpress',
  DB_USER: process.env.DB_USER || 'wordpress',
  DB_PASSWORD: process.env.DB_PASSWORD || 'wordpress',
  DB_TABLE_PREFIX: process.env.DB_TABLE_PREFIX || 'wp_',
  DB_HOST: process.env.DB_HOST || 'mysql',
  VOLUME_WORDPRESS_PATH: process.env.VOLUME_WORDPRESS_PATH || '../../../', // defaults to assuming user's WordPress install is in the same folder as node_modules
  VOLUME_LOCAL_PACKAGES_PATH: process.env.VOLUME_LOCAL_PACKAGES_PATH || '../../../packages',
  VOLUME_LOCAL_PLUGINS_PATH: process.env.VOLUME_LOCAL_PLUGINS_PATH || '../../../plugins',
  VOLUME_LOCAL_THEMES_PATH: process.env.VOLUME_LOCAL_THEMES_PATH || '../../../themes'
};

yargs
  .command({
    command: 'docker-compose',
    aliases: ['dc'], 
    describe: 'Execute docker-compose commands',
    handler: (argv) => {
      // Get the subcommands and arguments to pass to docker-compose.
      // Important: yargs will parse flags like "-d" and remove them from argv._,
      // so we must forward raw args after "dc" (or "docker-compose") verbatim.
      const rawArgs = process.argv.slice(2);
      const dcIdx = rawArgs.findIndex((a) => a === 'dc' || a === 'docker-compose');
      const dockerComposeArgs = (dcIdx >= 0 ? rawArgs.slice(dcIdx + 1) : argv._.slice(1)).join(' ');

      // ensure that any env variables that weren't provided by user are set using default values:
      for (const [key, value] of Object.entries(envVariables)) {
        process.env[key] = value;
      }

      // Execute docker-compose commands
      const dockerComposeFileArgs = dockerComposePaths.map((p) => `-f "${p}"`).join(' ');
      const dockerComposeProcess = exec(
        `docker-compose ${dockerComposeFileArgs} ${dockerComposeArgs}`,
        (error, stdout, stderr) => {
          if (error) {
            console.error(`Error executing docker-compose command: ${error}`);
            return;
          }

          console.log(stdout);
          console.error(stderr);
        }
      );

      // Forward docker-compose output to the console
      dockerComposeProcess.stdout.pipe(process.stdout);
      dockerComposeProcess.stderr.pipe(process.stderr);

    },
  })
  .help().argv;