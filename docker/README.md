# docker-go-http-tunnel

Docker image for running [panta/go-http-tunnel](https://github.com/mmatczuk/go-http-tunnel).

The docker support is originally based on [osiloke/go-http-tunnel](https://github.com/osiloke/go-http-tunnel/tree/master/docker), and [grugnog/go-http-tunnel](https://github.com/grugnog/go-http-tunnel/tree/master/docker) but provides more flexibility and contains both server and client binaries.

## Install

```
docker pull panta/go-http-tunnel
```

## Usage

### Docker run env options

This image can be run using a couple of environment variables that configures the image.

#### Common to client and server

| VARIABLE | DESCRIPTION | DEFAULT |
| :------- | :---------- | :------ |
| COUNTY | Certificate subject country string | US |
| STATE | Certificate subject state string | New Jersey |
| LOCATION | Certificate subject location string | Somewhere |
| ORGANISATION | Certificate subject organisation string | Organisation |
| ROOT_CN | Root certificate common name | Root |
| ROOT_NAME | Root certificate filename | root |
| ISSUER_CN | Intermediate issuer certificate common name | Issuer Ltd |
| ISSUER_NAME | Intermediate issuer certificate filename | issuer |
| SERVER_CN | Server certificate common name | *.tunnel.test |
| SERVER_NAME | Server certificate filename | server |
| CLIENT_CN | Client certificate common name | client.test |
| CLIENT_NAME | Client certificate filename | client |
| RSA_KEY_NUMBITS | The size of the rsa keys to generate in bits | 2048 |
| DAYS | The number of days to certify the certificates for | 365 |

#### TunnelD config

| VARIABLE | DESCRIPTION | DEFAULT |
| :------- | :---------- | :------ |
| DEBUG | turn on debugging | false |
| CLIENTS | Specify comma separated client ID's that should recognize | empty |
| DISABLE_HTTPS | Disables https | false |

#### Tunnel config


| VARIABLE | DESCRIPTION | DEFAULT |
| :------- | :---------- | :------ |
| TUNNEL_CONFIG | config file | /tunnel.yml |

### Server Side

```bash
$ docker run -v $PWD/certs:/etc/ssl/certs -p 4443:4443 panta/go-http-tunnel tunneld
```

The certificate directories, port and the tunneld command can be easily changed based upon your needs.

To get help on the command parameters, run:

```bash
$ docker run --rm panta/go-http-tunnel tunneld -h
```

### Client Side

A simple example:

```bash
$ docker run -d -v ./tunnel.yml:/tunnel.yml -v $PWD/certs:/etc/ssl/certs panta/go-http-tunnel tunnel
```

The format of the configuration file is described in [panta/go-http-tunnel](https://github.com/panta/go-http-tunnel#configuration).

To get help on the command parameters, run:

```bash
$ docker run --rm panta/go-http-tunnel tunnel -h
```

## Build

Clone this repository and run:

```bash
$ docker build -t go-http-tunnel .
```

## License

MIT License
