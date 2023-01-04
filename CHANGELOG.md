# Changelog

## [0.4.0](https://github.com/contiamo/terraform/compare/v0.3.0...v0.4.0) (2023-01-04)


### Features

* Add Tailscale module ([15a250b](https://github.com/contiamo/terraform/commit/15a250bc897407678f5858e8a599a8509b1439e7))


### Bug Fixes

* Add missing variable for tailscale module ([9ef864b](https://github.com/contiamo/terraform/commit/9ef864b2d7b9fb0d2bc826a67867fe23e3260482))
* Insure tailscale namespace exists ([c7187d0](https://github.com/contiamo/terraform/commit/c7187d02d8ff38ecd9465391a330866406033afd))

## [0.3.0](https://github.com/contiamo/terraform/compare/v0.2.1...v0.3.0) (2022-12-16)


### Features

* Remove archived template_file provider in favour of templatefile function ([7578171](https://github.com/contiamo/terraform/commit/7578171210cee2bd5cb3387ad0d3bc5e44243930))


### Bug Fixes

* Disable kubernetes provider config. Should be set by users ([2466edb](https://github.com/contiamo/terraform/commit/2466edb0eeccefac78a42a18ed7f117244aac428))
* Now actually removing the template_file block ([2b16d01](https://github.com/contiamo/terraform/commit/2b16d01b53beb42aeed02e21e4353274325b96cc))
* removing provider config from Datahub module ([fac340a](https://github.com/contiamo/terraform/commit/fac340a4075ea4fa547de9cf8b01a9c5720abd8c))


### Miscellaneous

* Better formatting for templatefile() input ([8815a05](https://github.com/contiamo/terraform/commit/8815a054969144cea05a2ae747d0a246bf72d600))
* Remove backend config: module users should set that ([2508202](https://github.com/contiamo/terraform/commit/2508202b0dfdb363e237080d4afd881bcef918fb))

### [0.2.1](https://github.com/contiamo/terraform/compare/v0.2.0...v0.2.1) (2022-11-01)


### Miscellaneous

* replace external actions with offical github script action ([f099785](https://github.com/contiamo/terraform/commit/f099785f1811e30fe3044116b34517d66db30ad1))

## [0.2.0](https://www.github.com/contiamo/terraform/compare/v0.1.0...v0.2.0) (2022-10-05)


### Features

* Add release please and semantic commits ([1e079d7](https://www.github.com/contiamo/terraform/commit/1e079d7fb8c5a78b07f7e024008045de307d125b))

## 0.1.0 (2022-10-04)


### Features

* Add Github module ([3ba477b](https://www.github.com/contiamo/terraform/commit/3ba477b164f2dfa98aa54f936936ae30dfa8694f))
* Add slack module ([618ec75](https://www.github.com/contiamo/terraform/commit/618ec75be33f6731ec810ca278ab161a84797588))
* Datahub module ([e4647ca](https://www.github.com/contiamo/terraform/commit/e4647ca93a7b8b70ad05ac6aee09cdb4450d9068))


### Miscellaneous

* Add README ([39a28d4](https://www.github.com/contiamo/terraform/commit/39a28d432fb58de816e328edad1c4705526ef585))
* Update datahub module readme ([56385e5](https://www.github.com/contiamo/terraform/commit/56385e5e6cf94532eb786b4143e23dcd5ee32aa0))
* Update READMEs and add gitignore ([c238528](https://www.github.com/contiamo/terraform/commit/c2385285a2d187f8664d25d7d5a6b679172cd6dd))
