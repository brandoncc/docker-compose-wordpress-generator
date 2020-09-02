docker-compose-wordpress-generator
==================================

This generator creates a docker-compose configuration which includes wordpress,
mysql, certbot (Let's Encrypt), and wp-cli.

You can configure the docker images you would like to use for each of these
services.

## Usage

```bash
ruby generate.rb
```
or, if you would like to update a configuration you created previously:

```bash
ruby generate.rb applications/the-app/generator-settings.yaml
```

This will generate the configurations in `applications/the-app/`.

Instructions for using the configurations are located at
`applications/the-app/instructions.txt`. It is very important that you review
them, as there are specific installation steps.

## Customizing PHP

You can update the PHP values by adding a `.user.ini` file to your application's root directory (which will be mounted at /var/www/html/ within the docker container).

## Environment Variables

After you run the generator, you will have a `.env` file located at
`applications/the-app/.env`. You can add more configuration values to this file,
which will make the added key/value pairs available as environment variables in
your docker containers.

## Idempotency

The generator is idempotent. Each time you run it, your settings are saved to a
configuration file so that you can use them as a starting point on a future run
of the generator. That allows you to just change one setting at a time.

In order to support this idempotency, the `.env` file is only written once. Each
time you run the generator after that, the .env file will retain its contents.

## Contributions

If you would like to contribute, please open a PR and provide a description of
your changes in the comments.

## Issues

If you find an issue, please open an issue.

## Credit

The configurations, and inspiration, for this tool came from
https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-with-docker-compose

Thank you for your awesome blog, Digital Ocean!
