# SFTPGo Dokku

This repo provides a `Dockerfile` to act as a helper to deploy [SFTPGo](https://github.com/drakkan/sftpgo/blob/main/docker/README.md) on Dokku.

SFTPGo is well suited to this as it already supports configuration via [Environment Variables](https://github.com/drakkan/sftpgo/blob/main/docs/full-configuration.md#environment-variables)

This `Dockerfile` and `README` will detail how to set up SFTPGo with Sqlite as the data provider and Dokku storage as the storage. Postgres or MySQL can be trivially dropped in with the same configuration just substituting the relevant dokku config and database plugin instead, STPGo then needs to be configured with the correct environment variable.

To use local storage as the backing for a folder in SFTPGo use `/srv/sftpgo/data/{subdirectory}`

The web interface will be available only on the configured app domain, however it should be noted the SFTP (& FTP if configured) ports will be accessible on the host and all domains pointed to it (unlike HTTP traffic SNI is unable to be used). This may make it undesirable to use SFTPGo on a Dokku instance with disparate apps (e.g. `sftp.example.com:2022` will be the SFP server but so will `unrelated-dokku-app.example.net:2022`)

We're using the [Nginx Stream Dokku Plugin](https://github.com/rjocoleman/dokku-nginx-stream) to provide TCP proxy. This may be undesirable in some environments. I have provided instructions to install my fork with a couple of the outstanding PRs merged.

### Preparing Dokku

To prepare Dokku.

1. Clone this repo, and work in it:

```shell
git clone https://github.com/rjocoleman/dokku-sftpgo && cd dokku-sftpgo
```

2. An app must be created and domain linked then set as ENV.

```shell
# app
dokku apps:create sftpgo
dokku domains:set sftp.yourdomain.com
```

3. Persistent storage must be created and added to the app:

```shell
# storage (on dokku server)
dokku storage:ensure-directory sftpgo --chown false
sudo mkdir -p /var/lib/dokku/data/storage/sftpgo/{backups,data,home}
sudo chown -R 1000:1000 /var/lib/dokku/data/storage/sftpgo
dokku storage:mount sftpgo /var/lib/dokku/data/storage/sftpgo/backups:/srv/sftpgo/backups
dokku storage:mount sftpgo /var/lib/dokku/data/storage/sftpgo/data:/srv/sftpgo/data
dokku storage:mount sftpgo /var/lib/dokku/data/storage/sftpgo/home:/var/lib/sftpgo
```

4. Add Application Ports:

This maps the chosen external host port to the container port 2022 and the container web interface 8080 to host proxy port 80.

```shell
# install (on the Dokku server the nginx stream plugin)
sudo dokku plugin:install https://github.com/rjocoleman/dokku-nginx-stream.git
# map the relevant ports
dokku proxy:ports-add sftpgo http:80:8080
dokku proxy:ports-add sftpgo tcp:2022:2022
```

You can add similar for port 2121 and the passive ports if you're using FTP (or WebDAV) too see [here](https://github.com/drakkan/sftpgo/blob/main/docker/README.md#enable-ftp-service) for more details.

5. The app must be deployed from this repo.

```shell
git remote add dokku dokku@dokkuinstance.com:sftpgo
git push dokku main
```

### External Database Data Provider Notes

To use an external database, a Dokku database plugin such as MySQL or Postgres must be installed and created. For example Postgres:

* Postgres must be installed and a database created and linked:

```shell
# database
dokku postgres:create sftpgo
dokku postgres:link sftpgo sftpgo
```

However the environment variables for SFTPGo must also be created, or a config file added to this repo and dropped into the relevant location. More details here: https://github.com/drakkan/sftpgo/blob/main/docs/full-configuration.md
