#!/usr/bin/env node

const { exec } = require('child_process');
const path = require('path');
const yargs = require('yargs');
const dotenv = require('dotenv');

dotenv.config(); // Load environment variables from the package user's own .env file
dotenv.config({ path: `.env.local`, override: true }); // also load user's .env.local and override clashing values from .env

const dockerComposePath = path.join(__dirname, '../docker-compose.yml');

const envVariables = {
  APP_NAME: process.env.APP_NAME || 'new-website',
  LOCAL_DOMAIN: process.env.LOCAL_DOMAIN || 'localhost',
  DB_ROOT_PASSWORD: process.env.DB_ROOT_PASSWORD || 'db_root_password',
  DB_TABLE_PREFIX: process.env.DB_TABLE_PREFIX || 'wp_',
  DB_HOST: process.env.DB_HOST || 'mysql',
  VOLUME_WORDPRESS_PATH: process.env.VOLUME_WORDPRESS_PATH || '../../../', // defaults to assuming user's WordPress install is in the same folder as node_modules
  VOLUME_LOCAL_PLUGINS_PATH: process.env.VOLUME_LOCAL_PLUGINS_PATH || '../../../plugins',
  VOLUME_LOCAL_THEMES_PATH: process.env.VOLUME_LOCAL_THEMES_PATH || '../../../themes'
};

yargs
  .command({
    command: 'docker-compose',
    aliases: ['dc'], 
    describe: 'Execute docker-compose commands',
    handler: (argv) => {
      // Get the subcommands and arguments to pass to docker-compose
      const dockerComposeArgs = argv._.slice(1).join(' ');

      // ensure that any env variables that weren't provided by user are set using default values:
      for (const [key, value] of Object.entries(envVariables)) {
        process.env[key] = value;
      }

      // Execute docker-compose commands
      exec(`docker-compose -f "${dockerComposePath}" ${dockerComposeArgs}`, (error, stdout, stderr) => {
        if (error) {
          console.error(`Error executing docker-compose command: ${error}`);
          return;
        }

        console.log(stdout);
        console.error(stderr);
      });

    },
  })
  // .command({
  //   command: 'docker',
  //   describe: 'Execute docker commands',
  //   handler: (argv) => {
  //     // Get the subcommands and arguments to pass to docker
  //     const dockerArgs = argv._.slice(1).join(' ');

  //     // Execute docker commands
  //     exec(`docker ${dockerArgs}`, (error, stdout, stderr) => {
  //       if (error) {
  //         console.error(`Error executing docker command: ${error}`);
  //         return;
  //       }

  //       console.log(stdout);
  //       console.error(stderr);
  //     });
  //   },
  // })
  .help().argv;