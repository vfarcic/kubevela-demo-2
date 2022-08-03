fancyingress: {
        annotations: {}
        attributes: {
            appliesToWorkloads: []
            conflictsWith: []
            podDisruptive:   false
            workloadRefPath: ""
        }
        description: "Silly Ingress trait"
        labels: {}
        type: "trait"
}

template: {
        outputs: ingress: {
            apiVersion: "networking.k8s.io/v1"
            kind:       "Ingress"
            metadata: {
                name: context.name
                annotations: "ingress.kubernetes.io/ssl-redirect": "false"
                labels: "app.kubernetes.io/name":                  context.name
            }
            spec: rules: [{
                host: parameter.host
                http: paths: [{
                    path: "/"
                    backend: service: {
                        name: context.name
                        port: number: context.output.spec.template.spec.containers[0].ports[0].containerPort
                    }
                    pathType: "ImplementationSpecific"
                }]
            }]
        }
        parameter: {
            host: string
        }
}