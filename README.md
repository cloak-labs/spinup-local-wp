# Spinup Local WP
Made by the [CloakWP](https://github.com/cloak-labs/cloakwp) team.

Spinup Local WP makes local WordPress development easy for projects using the [Bedrock](https://roots.io/bedrock/) boilerplate by Roots (currently untested with regular WordPress) -- which is designed for developers who want to manage their projects with Git and Composer. It also works with [CloakWP Bedrock](https://github.com/cloak-labs/cloakwp-bedrock), our modified version of Bedrock specifically tuned for CloakWP headless WordPress projects.

It works similarly to how `@wordpress/env` abstracts the complexity of managing your own Docker setup, providing a set of simple commands to magically spin up your local WordPress instance; however, unlike `@wordpress/env`, Spinup Local WP isn't designed to only handle transient dev environments solely for the purpose of testing custom plugins/themes; it is meant to be used alongside your real, version-controlled WordPress instance.

It's an NPM package that acts as an abstraction layer over a typical, best-practice [Docker + Docker Compose](https://docs.docker.com/compose/) setup for WordPress. It includes the following services/features:
  - PHP 8.1,
  - Nginx server,
  - MariaDB (popular MySQL fork),
  - [WP-CLI](https://wp-cli.org/) - the command-line interface for WordPress,
  - [PhpMyAdmin](https://www.phpmyadmin.net/) - free database administration tool
  - [MailHog](https://github.com/mailhog/MailHog) - an email testing tool for developers -- configure your outgoing SMTP server and view your outgoing email in a web UI.

# Getting Started
## Requirements
You must download/install the following:
- Composer
- PHP >= 8.0
- [Docker](https://www.docker.com/get-started) + Docker Compose + Docker Desktop
- NPM
- Node.js

## Install
If you're building a headless WordPress project, you should strongly consider using [CloakWP Bedrock](https://github.com/cloak-labs/cloakwp-bedrock), which comes with Spinup Local WP pre-installed and configured.

Otherwise, if you're using the regular Bedrock boilerplate, follow these steps: 
1. Spin up a new WordPress project using [Bedrock](https://roots.io/bedrock/) via `composer create-project roots/bedrock` (already have a WP install? skip to step #4).
2. cd into the newly created folder (and optionally run `code .` to open it in VS Code)
3. Optionally follow the [other steps](https://roots.io/bedrock/docs/installation/) outlined in Bedrock's installation docs
4. Run `npm init` and follow the prompts to generate a `package.json` file
5. Run `npm install @cloakwp/spinup-local-wp`
6. Add the following to your package.json's `scripts`:
  ```json
  "dev": "spinup-local-wp dc up",
  "down": "spinup-local-wp dc down",
  "stop": "spinup-local-wp dc stop",
  "composer": "spinup-local-wp dc run composer",
  "generate-env": "php -r \"copy('.env.example', '.env');\""
  "spinup-local-wp": "spinup-local-wp"
  ```
7. Create a `.env` file from `.env.example` and add this variable: `APP_NAME='enter-project-name'`; optionally add other env variables, as noted in the [example file here](https://github.com/cloak-labs/spinup-local-wp/.env.example), to further customize Spinup Local WP's behavior. For example, if WordPress is not properly spinning up when following the next "Run" steps below, it's likely because you need to adjust the `VOLUME_WORDPRESS_PATH` to point to your WordPress installation folder (should work out of the box if using NPM, but not PNPM, for example).


## Run
- open the Docker Desktop app, 
- from your WordPress project root, run:
```shell
npm run dev
``` 
... assuming you configured the `dev` script from above, this will run `spinup-local-wp docker-compose up` for you.
- access your local WordPress instance from http://localhost/wp/wp-admin
- access PhpMyAdmin from http://127.0.0.1:8082/
- access MailHog from http://0.0.0.0:8025/

## Common Issues

### 1. Can't upload images
If you get an error along the lines of "Unable to create directory uploads/2023/08. Is its parent directory writable by the server?" when uploading images to the WP Media Library, you must reset the permissions of the `uploads` folder:

1. Run your project
2. In Docker Desktop, click into the `nginx` container, and under the `Terminal` tab run the following:
```bash
cd var/www/html/web/app
chown -R www-data:www-data uploads
chmod -R 755 uploads
```
3. Try uploading an image again and it should work

## Tools

### Update WordPress Core and Composer packages (plugins/themes)

From your project root, run:

```shell
npm run composer update
```
---
### Use WP-CLI

First, login to the WordPress Docker container:

```shell
docker exec -it {my-website}-wordpress bash
```
... replacing {my-website} with the APP_NAME env variable value you set during the "Install" steps above.

Then, run a wp-cli command:

```shell
wp search-replace https://olddomain.com https://newdomain.com --allow-root
```

---
### Useful Docker Commands

Login to the docker container

```shell
docker exec -it {container-name} bash
```

To run Docker Compose commands, use the `spinup-local-wp` command followed by `docker-compose`, or `dc` for short, followed by the Docker Compose command you wish to run (eg. `stop`, `down`, etc.). Examples:

Stop

```shell
npm run spinup-local-wp dc stop
```

Down (stop and remove)

```shell
npm run spinup-local-wp dc down
```

Cleanup

```shell
npm run spinup-local-wp dc rm -v
```

Recreate

```shell
npm run spinup-local-wp dc up -d --force-recreate
```

Rebuild docker container when Dockerfile has changed due to package update

```shell
npm run spinup-local-wp dc up -d --force-recreate --build
```
</details>
