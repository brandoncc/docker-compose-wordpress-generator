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

## Basic Auth

If you would like to use basic auth, follow the instructions in
`applications/the-app/nginx-auth/instructions.txt` after you generate the
application.

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

## Known Issues

If you are deploying a new server (different IP) for a domain which already uses
Let's Encrypt, running `docker-compose up -d` with Let's Encrypt in sandbox mode
will not work. The entire system will fail to come online. There are two
options:

1. Change Let's Encrypt to "live" during the initial application generation.
   ** This runs the risk of being rate limited by Let's Encrypt if you have to
   keep starting over for any reason. **
2. Comment out the certbot container in docker-compose after generating your
   application. After you have confirmed that `docker-compose ps` looks good for
   the first time, run the generator again, set Let's Encrypt to "live", and
   upload the new configuration. Then you can `docker-compose up -d` again, and
   Let's Encrypt should issue the certificate as usual.

---

Changing domains on an existing site can be problematic. For example:

If you initially use: `example.com,a.example.com,b.example.com`

and then change to: `example.com,a.example.com` (dropping `b.example.com`)

The new cert will be located at `/etc/letsencrypt/live/example.com-0001/`

The generator will not know this though, so it expects the cert to be located at
`/etc/letsencrypt/live/example.com/`.

The outcome is that the nginx config is written using the expected path, not the
actual one. This means the application will continue using
`/etc/letsencrypt/live/example.com/`, which is presumably a certificate that is
going to expire.

## Contributions

If you would like to contribute, please open a PR and provide a description of
your changes in the comments.

## Issues

If you find an issue, please open an issue.

## Credit

The configurations, and inspiration, for this tool came from
https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-with-docker-compose

Thank you for your awesome blog, Digital Ocean!
