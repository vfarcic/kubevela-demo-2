#!/usr/bin/env nu

source scripts/kubernetes.nu
source scripts/ingress.nu
source scripts/crossplane.nu
source scripts/common.nu
source scripts/kubevela.nu

def main [] {}

def "main setup" [] {

    rm --force .env

    let hyperscaler = main get hyperscaler

    main create kubernetes kind

    let ingress_data = (
        main apply ingress nginx --hyperscaler kind
    )

    main apply crossplane --hyperscaler $hyperscaler --db true

    if $hyperscaler == "azure" {

        let date_suffix = (date now | format date "%Y%m%d%H%M%S")

        open db-azure.yaml |
            | upsert spec.components.0.name $"silly-demo-db-($date_suffix)"
            | save db-azure.yaml --force

        open db-azure-password.yaml |
            | upsert metadata.name $"silly-demo-db-($date_suffix)-password"
            | save db-azure-password.yaml --force

        open app.yaml |
            | upsert spec.policies.4.properties.components.0.properties.db.secret $"silly-demo-db-($date_suffix)"
            | save app.yaml --force

    } else {

        open app.yaml |
            | upsert spec.policies.4.properties.components.0.properties.db.secret "silly-demo-db"
            | save app.yaml --force

    }

    main apply kubevela $"vela.($ingress_data.host)"

    main print source

}

def "main destroy" [
    hyperscaler: string
] {

    if $hyperscaler == "google" {

        gcloud projects delete $env.PROJECT_ID --quiet

    }

    main destroy kubernetes kind

}