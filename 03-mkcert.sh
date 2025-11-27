#!/bin/bash
#

set -e

source variables

brew install mkcert nss
mkcert -install
