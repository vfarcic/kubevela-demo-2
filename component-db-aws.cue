import "encoding/base64"

"db-aws": {
    attributes: {
        workload: definition: {
            apiVersion: "rds.aws.upbound.io/v1beta2"
            kind:       "Instance"
        }
        // status: healthPolicy: "isHealth: (context.output.status.readyReplicas > 0) && (context.output.status.readyReplicas == context.output.status.replicas)"
    }
    type: "component"
}

template: {
    parameter: {
        region:  *"us-east-1" | string
        size:    string
        version: string
    }
    output: {
        apiVersion: "rds.aws.upbound.io/v1beta2"
        kind: "Instance"
        metadata: {
            name:   context.name + "-" + context.namespace
            labels: "app.kubernetes.io/name": context.name
        }
        spec: forProvider: {
            region: parameter.region
            dbSubnetGroupNameRef: name: context.name + "-" + context.namespace
            vpcSecurityGroupIdRef: name: context.name + "-" + context.namespace
            username: "masteruser"
            engine: "postgres"
            skipFinalSnapshot: true
            publiclyAccessible: true
            allocatedStorage: 200
            passwordSecretRef: {
                name: context.name + "-password"
                namespace: context.namespace
                key: "password"
            }
            identifier: context.name + "-" + context.namespace
            if parameter.size == "small" {
                instanceClass: "db.m5.large"
            }
            if parameter.size == "medium" {
                instanceClass: "db.m5.2xlarge"
            }
            if parameter.size == "large" {
                instanceClass: "db.m5.8xlarge"
            }
            engineVersion: parameter.version
        }
    }
    outputs: {
        #Metadata: {
            name:   context.name + "-" + context.namespace
            labels: "app.kubernetes.io/name": context.name
        }
        vpc: {
            apiVersion: "ec2.aws.upbound.io/v1beta1"
            kind:       "VPC"
            metadata: #Metadata
            spec: forProvider: {
                region:             parameter.region
                cidrBlock:          "11.0.0.0/16"
                enableDnsSupport:   true
                enableDnsHostnames: true
            }
        }
        internetGateway: {
            apiVersion: "ec2.aws.upbound.io/v1beta1"
            kind:       "InternetGateway"
            metadata: #Metadata
            spec: forProvider: {
                region:   parameter.region
                vpcIdRef: name: context.name + "-" + context.namespace
            }
        }
        routeTable: {
            apiVersion: "ec2.aws.upbound.io/v1beta1"
            kind: "RouteTable"
            metadata: #Metadata
            spec: forProvider: {
                region: parameter.region
                vpcIdRef: name: context.name + "-" + context.namespace
            }
        }
        mainRouteTableAssociation: {
            apiVersion: "ec2.aws.upbound.io/v1beta1"
            kind: "MainRouteTableAssociation"
            metadata: #Metadata
            spec: forProvider: {
                region: parameter.region
                routeTableIdRef: name: context.name + "-" + context.namespace
                vpcIdRef: name: context.name + "-" + context.namespace
            }
        }
        route: {
            apiVersion: "ec2.aws.upbound.io/v1beta1"
            kind: "Route"
            metadata: #Metadata
            spec: forProvider: {
                region: parameter.region
                routeTableIdRef: name: context.name + "-" + context.namespace
                destinationCidrBlock: "0.0.0.0/0"
                gatewayIdRef: name: context.name + "-" + context.namespace
            }
        }
        securityGroup: {
            apiVersion: "ec2.aws.upbound.io/v1beta1"
            kind: "SecurityGroup"
            metadata: #Metadata
            spec: forProvider: {
                region: parameter.region
                description: "I am too lazy to write descriptions"
                vpcIdRef: name: context.name + "-" + context.namespace
            }
        }
        securityGroupRule: {
            apiVersion: "ec2.aws.upbound.io/v1beta1"
            kind: "SecurityGroupRule"
            metadata: #Metadata
            spec: forProvider: {
                region: parameter.region
                description: "I am too lazy to write descriptions"
                type: "ingress"
                fromPort: 5432
                toPort: 5432
                protocol: "tcp"
                cidrBlocks: ["0.0.0.0/0"]
                securityGroupIdRef: name: context.name + "-" + context.namespace
            }
        }
        _zoneList: [
            { zone: "a", cidrBlock: "11.0.0.0/24" },
            { zone: "b", cidrBlock: "11.0.1.0/24"  },
            { zone: "c", cidrBlock: "11.0.2.0/24"  }
        ]
        for k, v in _zoneList {
            "subnet\(v.zone)": {
                apiVersion: "ec2.aws.upbound.io/v1beta1"
                kind: "Subnet"
                metadata: {
                    name:   context.name + "-" + v.zone + "-" + context.namespace
                    labels: {
                        "app.kubernetes.io/name": context.name
                        zone: parameter.region + v.zone
                    }
                }
                spec: forProvider: {
                    region: parameter.region
                    availabilityZone: parameter.region + v.zone
                    cidrBlock: v.cidrBlock
                    vpcIdRef: name: context.name + "-" + context.namespace
                }
            }
        }
        subnetGroup: {
            apiVersion: "rds.aws.upbound.io/v1beta1"
            kind: "SubnetGroup"
            metadata: #Metadata
            spec: forProvider: {
                region: parameter.region
                description: "I'm too lazy to write a good description"
                subnetIdRefs: [
                    for k, v in _zoneList {
                        name: context.name + "-" + v.zone + "-" + context.namespace
                    }
                ]
            }
        }
        secret: {
            apiVersion: "v1"
            kind: "Secret"
            metadata: #Metadata
            data: {
                username: base64.Encode(null, output.spec.forProvider.username)
                // password: output.spec.forProvider.username
                // endpoint: base64.Encode(null, output.status.atProvider.address)
                port: "NTQzMg=="
            }
        }
        //       spec: {
        //           references: [{
        //               patchesFrom: {
        //                   apiVersion: "v1"
        //                   kind: "Secret"
        //                   name: oxr.spec.id + "-password"
        //                   namespace: oxr.spec.claimRef.namespace
        //                   fieldPath: "data.password"
        //               }
        //               toFieldPath: "data.password"
        //           }, {
        //               patchesFrom: {
        //                   apiVersion: "rds.aws.upbound.io/v1beta1"
        //                   kind: "Instance"
        //                   name: oxr.spec.id
        //                   namespace: "crossplane-system"
        //                   fieldPath: "status.atProvider.address"
        //               }
        //               toFieldPath: "stringData.endpoint"
        //           }]
        //       }
        //   }, {
        //       **oxr
        //       if "rdsinstance" in ocds:
        //           status.address: ocds["rdsinstance"].Resource.status.atProvider.address
        //   }]

        //   _items += [{
        //       apiVersion: "ec2.aws.upbound.io/v1beta1"
        //       kind: "RouteTableAssociation"
        //       metadata: {
        //           name: oxr.spec.id + "-1" + _data.zone
        //           annotations: {
        //               "krm.kcl.dev/composition-resource-name": "routeTableAssociation1" + _data.zone
        //           }
        //       }
        //       spec: forProvider: {
        //           region: parameter.region
        //           routeTableIdSelector.matchControllerRef: true
        //           subnetIdSelector: {
        //               matchControllerRef: true
        //               matchLabels.zone: parameter.region + _data.zone
        //           }
        //       }
        //   } for _data in _zoneList]
    }
}
                // metadata: labels: "app.kubernetes.io/name": context.name
                // spec: containers: [{
                //     image: parameter.image + ":" + parameter.tag
                //     livenessProbe: httpGet: {
                //         path: "/"
                //         port: parameter.port
                //     }
                //     name: "backend"
                //     ports: [{ containerPort: 80 }]
                //     readinessProbe: httpGet: {
                //         path: "/"
                //         port: parameter.port
                //     }
                //     resources: {
                //         limits: {
                //             cpu:    "250m"
                //             memory: "256Mi"
                //         }
                //         requests: {
                //             cpu:    "125m"
                //             memory: "128Mi"
                //         }
                //     }
                //     if parameter.db.secret != _|_ {
                //         env: [{
                //             name: "DB_ENDPOINT"
                //             valueFrom: secretKeyRef: {
                //                 key:  "endpoint"
                //                 name: parameter.db.secret
                //             }
                //         }, {
                //             name: "DB_PASSWORD"
                //             valueFrom: secretKeyRef: {
                //                 key:  "password"
                //                 name: parameter.db.secret
                //             }
                //         }, {
                //             name: "DB_PORT"
                //             valueFrom: secretKeyRef: {
                //                 key:      "port"
                //                 name:     parameter.db.secret
                //                 optional: true
                //             }
                //         }, {
                //             name: "DB_USERNAME"
                //             valueFrom: secretKeyRef: {
                //                 key:  "username"
                //                 name: parameter.db.secret
                //             }
                //         }, {
                //             name:  "DB_NAME"
                //             value: context.name
                //         }]
                //     }
                // }]
    // outputs: {
    //     service: {
    //         apiVersion: "v1"
    //         kind:       "Service"
    //         metadata: {
    //             name:   context.name
    //             labels: "app.kubernetes.io/name": context.name
    //         }
    //         spec: {
    //             selector: "app.kubernetes.io/name": context.name
    //             type: "ClusterIP"
    //             ports: [{
    //                 port:       parameter.port
    //                 targetPort: parameter.port
    //                 protocol:   "TCP"
    //                 name:       "http"
    //             }]
    //         }
    //     }
    //     ingress: {
    //         apiVersion: "networking.k8s.io/v1"
    //         kind:       "Ingress"
    //         metadata: {
    //             name:        context.name
    //             labels:      "app.kubernetes.io/name": context.name
    //             annotations: "ingress.kubernetes.io/ssl-redirect": "false"
    //         }
    //         spec: {
    //             if parameter.ingressClassName != _|_ {
    //                 ingressClassName: parameter.ingressClassName
    //             }
    //             rules: [{
    //                 host: parameter.host
    //                 http: paths: [{
    //                     path:     "/"
    //                     pathType: "ImplementationSpecific"
    //                     backend: service: {
    //                         name:         context.name
    //                         port: number: parameter.port
    //                     }
    //                 }]
    //             }]
    //         }
    //     }
    // }
