# Changelog

### [0.6.1](https://github.com/contiamo/terraform/compare/v0.6.0...v0.6.1) (2025-05-11)


### Bug Fixes

* Remove comments from alloy config ([bbebac8](https://github.com/contiamo/terraform/commit/bbebac8811a8af767c4f29e720e39591eff743cb))

## [0.6.0](https://github.com/contiamo/terraform/compare/v0.5.0...v0.6.0) (2025-05-11)


### Features

* Add Azure OpenAI ([8c7ecf1](https://github.com/contiamo/terraform/commit/8c7ecf1c34d62a93efff47537d391aa2b62a74c2))
* Add blackbox exporter to Monitoring ([36d77d1](https://github.com/contiamo/terraform/commit/36d77d1c374e5163ee1e57bfe544ca4e6c24d4c2))
* Add metadata labels to alerts ([2a6a312](https://github.com/contiamo/terraform/commit/2a6a3127d82f803fd2e4d382b3a8d2c2c7fe67bc))
* Add separate alert rules for blackbox exporter ([7fc7dc7](https://github.com/contiamo/terraform/commit/7fc7dc718d7a5d44a77b08e4a5a7ecc8e3c88c48))
* Add slack notifications to monitoring ([fce3e3c](https://github.com/contiamo/terraform/commit/fce3e3c7f9d68b5332f30fd9b4c750aad7e9af6d))
* Make blackbox exporter optional ([ab76045](https://github.com/contiamo/terraform/commit/ab760452b22ba5cf426700506ad2c2f687de799b))
* Relax NginxLatency alert ([3ae4807](https://github.com/contiamo/terraform/commit/3ae4807715745af222ebc2a0e5ec42c6a655c7a3))


### Bug Fixes

* alertmanager template ([19eefe3](https://github.com/contiamo/terraform/commit/19eefe3df1d66ce313b4257a49e6842042fe17c7))
* alertmanager template ([b43eddc](https://github.com/contiamo/terraform/commit/b43eddc665ff7563988b2b34bc9dc9c3c1ec1b3d))
* Blackbox exporter alert text ([72136c2](https://github.com/contiamo/terraform/commit/72136c27e735ab41342c648ca808e6deb7909708))
* Do not use template for webpoint alert ([fadb41a](https://github.com/contiamo/terraform/commit/fadb41ae4eb5c8f6cf21eeac27f4419597f37502))
* Grafana host in monitoring ([11c8e07](https://github.com/contiamo/terraform/commit/11c8e07c534c528570b0ac227ca9c4f246195e68))
* InfoInhibitor to be routed to null ([27c7164](https://github.com/contiamo/terraform/commit/27c71649846acddb16b47a38a10f7a2e4758e164))
* inhibit_rules in monitoring ([fa38a40](https://github.com/contiamo/terraform/commit/fa38a40d03b106674d567eda7743de56b863f138))
* Inhibitors and info alerts ([9045a22](https://github.com/contiamo/terraform/commit/9045a2201a7c4b5892b94967253378668bc32a90))
* Missing extension in alertmanager template ([71e1654](https://github.com/contiamo/terraform/commit/71e1654084f990ae3745982b305b014c7015b573))
* Missing extension in alertmanager template ([c7e3cdf](https://github.com/contiamo/terraform/commit/c7e3cdff4a40fc30df594b2e38e9f1c1663f818d))
* Reformat Blackbox exporter alert text ([11d8b29](https://github.com/contiamo/terraform/commit/11d8b2994eac67a158c31992d6083b21c62fb10d))
* Remove extra / in grafana log path ([9258f2a](https://github.com/contiamo/terraform/commit/9258f2af470bb7e0dae4896927d25850dad5e0b5))
* Set intall blackbox exporter default to true ([716eec4](https://github.com/contiamo/terraform/commit/716eec45b0bb68b9b2483ac794296ea1a5593b39))


### Miscellaneous

* Adjust NginxErrors alert to fire on 10 4** and 5** a minute ([42964bf](https://github.com/contiamo/terraform/commit/42964bf64fd84914f6275479af9331fd3da2ac8e))
* Disable cole alerts ([3259219](https://github.com/contiamo/terraform/commit/32592193ebfbd2933c1f7ab619ce974334536d71))
* Extract alert web endpoint text to a template ([77fad5f](https://github.com/contiamo/terraform/commit/77fad5fdfc15346e6b653b0b69a5e201d50a78aa))
* Set default blackbox exporter version ([455deaf](https://github.com/contiamo/terraform/commit/455deaf175aa52e9909c4a9404c5298c4949538b))
* Trigger update ([d5934de](https://github.com/contiamo/terraform/commit/d5934de0b7fef12a4156764787ebd0581400aad6))
* Update gitignore ([c157f59](https://github.com/contiamo/terraform/commit/c157f59fd80a80f49a51952e81d6c685c1982822))
* Update monitoring module docs ([7f0b929](https://github.com/contiamo/terraform/commit/7f0b929fb274745d0f3bf780f73f4042bf138170))

## [0.5.0](https://github.com/contiamo/terraform/compare/v0.4.0...v0.5.0) (2024-06-18)


### Features

* Add an option to set tailscale subnet router name ([657ff89](https://github.com/contiamo/terraform/commit/657ff89b4799bba6cbdcad7863227ad78394e655))
* Add cloned mwaa module ([7ad0354](https://github.com/contiamo/terraform/commit/7ad03544d3b8621ee1e4c854518f735992dfcb61))
* Add ECR pull helper ([adf3f71](https://github.com/contiamo/terraform/commit/adf3f717c9b74328d6f5637ddd35843222f0a71e))
* Add EKS Monitoring stack module ([71e4477](https://github.com/contiamo/terraform/commit/71e4477171ef22744b3717a8714cf2346830c74d))
* Add Elasticsearch module ([4586064](https://github.com/contiamo/terraform/commit/4586064f1f088fa06af0c581d267c46db70e2ec8))


### Bug Fixes

* ECR helper: add missing script ([2dd3e73](https://github.com/contiamo/terraform/commit/2dd3e73999f8347597926ea901fa96a4a8158186))
* Missing aws account ref in ecr helper ([dcd327e](https://github.com/contiamo/terraform/commit/dcd327ef12e27a6396018dd26b8e4f07533d809d))
* Reference router name var. in Tailscale module ([1add8fc](https://github.com/contiamo/terraform/commit/1add8fc64db95a0a83bbeb83b734db0f93edc791))


### Miscellaneous

* Upadte Monitoring module docs ([62825ab](https://github.com/contiamo/terraform/commit/62825abf4670b80d1441bc7f51f6c04303d4ea8e))
* Update External DNS module docs ([dde6819](https://github.com/contiamo/terraform/commit/dde68190270dfd9d59c3daee76cc19a3722145aa))
* Update README with correct source reference ([c9c0f17](https://github.com/contiamo/terraform/commit/c9c0f17b9067952f50bb97a171199fa8e9a7f1a6))

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
