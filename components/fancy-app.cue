"fancyapp": {
	annotations: {}
	attributes: workload: definition: {
		apiVersion: "apps/v1"
		kind:       "Deployment"
	}
	description: "Silly application component"
	labels: {}
	type: "component"
}
template: {
	output: {
		apiVersion: "apps/v1"
		kind:       "Deployment"
		metadata: {
			name: context.name
			labels: "app.kubernetes.io/name": context.name
		}
		spec: {
			selector: matchLabels: "app.kubernetes.io/name": context.name
			template: {
				metadata: labels: "app.kubernetes.io/name": context.name
				spec: containers: [{
					name:  context.name
					image: parameter.image
					livenessProbe: httpGet: {
						path: "/"
						port: parameter.port
					}
					ports: [{
						containerPort: parameter.port
					}]
					readinessProbe: httpGet: {
						path: "/"
						port: parameter.port
					}
					resources: {
						limits: {
							cpu:    parameter.cpuLimit
							memory: parameter.memLimit
						}
						requests: {
							cpu:    parameter.cpuReq
							memory: parameter.memReq
						}
					}
				}]
			}
		}
	}
	outputs: service: {
		apiVersion: "v1"
		kind:       "Service"
		metadata: {
			name: "silly-demo"
			labels: "app.kubernetes.io/name": context.name
		}
		spec: {
			ports: [{
				name:       "http"
				port:       parameter.port
				protocol:   "TCP"
				targetPort: parameter.port
			}]
			selector: "app.kubernetes.io/name": context.name
			type: "ClusterIP"
		}

	}
	parameter: {
		image: string
		port: *8080 | int
		cpuLimit: *"500m" | string
		memLimit: *"512Mi" | string
		cpuReq: *"250m" | string
		memReq: *"256Mi" | string
	}
}

