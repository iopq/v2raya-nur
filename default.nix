{ lib
, fetchFromGitHub
, mkYarnPackage
, fetchYarnDeps
, buildGoModule
, makeWrapper
, xray
#, v2ray-geoip
#, v2ray-domain-list-community
, symlinkJoin
}:
let
  pname = "v2raya";
  version = "1.5.5";
  src = fetchFromGitHub {
    owner = "v2rayA";
    repo = "v2rayA";
    rev = "v${version}";
    sha256 = "sha256-9RzN81C2ux5o3PQI3zUzCvfvDr2aylrZFoThdEBO4jg=";
  };
  web = mkYarnPackage {
    inherit pname version;
    src = "${src}/gui";

    yarnNix = ./yarn.nix;
    yarnLock = ./yarn.lock;
    packageJSON = ./package.json;

    # https://github.com/webpack/webpack/issues/14532
    buildPhase = ''
      export NODE_OPTIONS=--openssl-legacy-provider
      ln -s $src/postcss.config.js postcss.config.js
      OUTPUT_DIR=$out yarn --offline build
    '';
    distPhase = "true";
    dontInstall = true;
    dontFixup = true;
  };
in
buildGoModule {
  inherit pname version;
  src = "${src}/service";
  vendorSha256 = "sha256-a4A5WD5B1SPzn8Va8EKZD7nd9mU+Rds1bIKCHClVgMI=";
  subPackages = [ "." ];
  nativeBuildInputs = [ makeWrapper ];
  preBuild = ''
    cp -a ${web} server/router/web
  '';
  postInstall = ''
    wrapProgram $out/bin/v2rayA \
      --prefix PATH ":" "${lib.makeBinPath [ xray ]}" \
      '';
 #     --prefix XDG_DATA_DIRS ":" ${symlinkJoin {
 #       name = "assets";
 #       paths = [ v2ray-geoip v2ray-domain-list-community ];
 #     }}/share
 # '';
  meta = with lib; {
    description = "A Linux web GUI client of Project V which supports V2Ray, Xray, SS, SSR, Trojan and Pingtunnel";
    homepage = "https://github.com/v2rayA/v2rayA";
    mainProgram = "v2rayA";
    license = licenses.agpl3Only;
  };
}

