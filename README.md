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

## Contributions

If you would like to contribute, please open a PR and provide a description of
your changes in the comments.

## Issues

If you find an issue, please open an issue.

## Credit

The configurations, and inspiration, for this tool came from
https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-with-docker-compose

Thank you for your awesome blog, Digital Ocean!
