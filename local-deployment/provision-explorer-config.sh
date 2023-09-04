#! /bin/bash
CL_PORT=$(kurtosis enclave inspect my-testnet | grep 4000/tcp | tr -s ' ' | cut -d " " -f 6 | sed -e 's/http\:\/\/127.0.0.1\://' | grep "\S")
echo "CL Node port is $CL_PORT"

EL_PORT=$(kurtosis enclave inspect my-testnet | grep 8545/tcp | tr -s ' ' | cut -d " " -f 5 | sed -e 's/127.0.0.1\://' | grep "\S")
echo "EL Node port is $EL_PORT"

REDIS_PORT=$(kurtosis enclave inspect my-testnet | grep 6379/tcp | tr -s ' ' | cut -d " " -f 6 | sed -e 's/tcp\:\/\/127.0.0.1\://' | grep "\S")
echo "Redis port is $REDIS_PORT"

POSTGRES_PORT=$(kurtosis enclave inspect my-testnet | grep 5432/tcp | tr -s ' ' | cut -d " " -f 6 | sed -e 's/postgresql\:\/\/127.0.0.1\://' | grep "\S")
echo "Postgres port is $POSTGRES_PORT"

LBT_PORT=$(kurtosis enclave inspect my-testnet | grep 9000/tcp | tr -s ' ' | cut -d " " -f 6 | sed -e 's/tcp\:\/\/127.0.0.1\://' | grep "\S")
echo "Little bigtable port is $LBT_PORT"

cat >config.yml <<EOL
chain:
  configPath: 'node'
readerDatabase:
  name: db
  host: 127.0.0.1
  port: "$POSTGRES_PORT"
  user: postgres
  password: "pass"
writerDatabase:
  name: db
  host: 127.0.0.1
  port: "$POSTGRES_PORT"
  user: postgres
  password: "pass"
bigtable:
  project: explorer
  instance: explorer
  emulator: true
  emulatorPort: $LBT_PORT
eth1ErigonEndpoint: 'http://127.0.0.1:$EL_PORT'
eth1GethEndpoint: 'http://127.0.0.1:$EL_PORT'
redisCacheEndpoint: '127.0.0.1:$REDIS_PORT'
tieredCacheProvider: 'redis'
frontend:
  siteDomain: "localhost:8080"
  siteName: 'Open Source Ethereum (ETH) Testnet Explorer' # Name of the site, displayed in the title tag
  siteSubtitle: "Showing a local testnet."
  server:
    host: '0.0.0.0' # Address to listen on
    port: '8080' # Port to listen on
  readerDatabase:
    name: db
    host: 127.0.0.1
    port: "$POSTGRES_PORT"
    user: postgres
    password: "pass"
  writerDatabase:
    name: db
    host: 127.0.0.1
    port: "$POSTGRES_PORT"
    user: postgres
    password: "pass"
  sessionSecret: "11111111111111111111111111111111"
  jwtSigningSecret: "1111111111111111111111111111111111111111111111111111111111111111"
  jwtIssuer: "localhost"
  jwtValidityInMinutes: 30
  maxMailsPerEmailPerDay: 10
  mail:
    mailgun:
      sender: no-reply@localhost
      domain: mg.localhost
      privateKey: "key-11111111111111111111111111111111"
  csrfAuthKey: '1111111111111111111111111111111111111111111111111111111111111111'
indexer:
  # fullIndexOnStartup: false # Perform a one time full db index on startup
  # indexMissingEpochsOnStartup: true # Check for missing epochs and export them after startup
  node:
    host: 127.0.0.1
    port: '$CL_PORT'
    type: lighthouse
  eth1DepositContractFirstBlock: 0
EOL

echo "generated config written to config.yml"

echo "initializing bigtable schema"
PROJECT="explorer"
INSTANCE="explorer"
HOST="127.0.0.1:$LBT_PORT"

go run ../cmd/misc/main.go -config config.yml -command initBigtableSchema

echo "bigtable schema initialization completed"

echo "provisioning postgres db schema"
go run ../cmd/misc/main.go -config config.yml -command applyDbSchema
echo "postgres db schema initialization completed"