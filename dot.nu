#!/usr/bin/env nu

source scripts/kubernetes.nu
source scripts/ingress.nu
source scripts/crossplane.nu
source scripts/common.nu

def main [] {}

def "main setup" [] {

    rm --force .env

    let hyperscaler = main get hyperscaler

    main create kubernetes kind

    let ingress_data = (
        main apply ingress nginx --hyperscaler kind
    )

    main apply crossplane --hyperscaler $hyperscaler --db true

    vela install

    (
        vela addon enable velaux
            domain=$"vela.($ingress_data.host)"
            gatewayDriver=nginx
    )

    start $"http://vela.($ingress_data.host)"

    main print source

}

def "main destroy" [] {

    main destroy kubernetes kind

}