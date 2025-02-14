{
  prometheusAlerts+:: {
    groups+: [
      {
        name: 'kubernetes-apps',
        rules: [
          {
            expr: |||
              rate(kube_pod_container_status_restarts_total{%(prefixedNamespaceSelector)s%(kubeStateMetricsSelector)s}[15m]) * 60 * 5 > 0
            ||| % $._config,
            labels: {
              severity: 'critical',
            },
            annotations: {
              message: 'Pod {{ $labels.namespace }}/{{ $labels.pod }} ({{ $labels.container }}) is restarting {{ printf "%.2f" $value }} times / 5 minutes.',
            },
            'for': '15m',
            alert: 'KubePodCrashLooping',
          },
          {
            expr: |||
              sum by (namespace, pod) (kube_pod_status_phase{%(prefixedNamespaceSelector)s%(kubeStateMetricsSelector)s, phase=~"Failed|Pending|Unknown"} * on(namespace, pod) group_left(owner_kind) kube_pod_owner{owner_kind!="Job"}) > 0
            ||| % $._config,
            labels: {
              severity: 'critical',
            },
            annotations: {
              message: 'Pod {{ $labels.namespace }}/{{ $labels.pod }} has been in a non-ready state for longer than 15 minutes.',
            },
            'for': '15m',
            alert: 'KubePodNotReady',
          },
          {
            expr: |||
              kube_deployment_status_observed_generation{%(prefixedNamespaceSelector)s%(kubeStateMetricsSelector)s}
                !=
              kube_deployment_metadata_generation{%(prefixedNamespaceSelector)s%(kubeStateMetricsSelector)s}
            ||| % $._config,
            labels: {
              severity: 'critical',
            },
            annotations: {
              message: 'Deployment generation for {{ $labels.namespace }}/{{ $labels.deployment }} does not match, this indicates that the Deployment has failed but has not been rolled back.',
            },
            'for': '15m',
            alert: 'KubeDeploymentGenerationMismatch',
          },
          {
            expr: |||
              kube_deployment_spec_replicas{%(prefixedNamespaceSelector)s%(kubeStateMetricsSelector)s}
                !=
              kube_deployment_status_replicas_available{%(prefixedNamespaceSelector)s%(kubeStateMetricsSelector)s}
            ||| % $._config,
            labels: {
              severity: 'critical',
            },
            annotations: {
              message: 'Deployment {{ $labels.namespace }}/{{ $labels.deployment }} has not matched the expected number of replicas for longer than 15 minutes.',
            },
            'for': '15m',
            alert: 'KubeDeploymentReplicasMismatch',
          },
          {
            expr: |||
              kube_statefulset_status_replicas_ready{%(prefixedNamespaceSelector)s%(kubeStateMetricsSelector)s}
                !=
              kube_statefulset_status_replicas{%(prefixedNamespaceSelector)s%(kubeStateMetricsSelector)s}
            ||| % $._config,
            labels: {
              severity: 'critical',
            },
            annotations: {
              message: 'StatefulSet {{ $labels.namespace }}/{{ $labels.statefulset }} has not matched the expected number of replicas for longer than 15 minutes.',
            },
            'for': '15m',
            alert: 'KubeStatefulSetReplicasMismatch',
          },
          {
            expr: |||
              kube_statefulset_status_observed_generation{%(prefixedNamespaceSelector)s%(kubeStateMetricsSelector)s}
                !=
              kube_statefulset_metadata_generation{%(prefixedNamespaceSelector)s%(kubeStateMetricsSelector)s}
            ||| % $._config,
            labels: {
              severity: 'critical',
            },
            annotations: {
              message: 'StatefulSet generation for {{ $labels.namespace }}/{{ $labels.statefulset }} does not match, this indicates that the StatefulSet has failed but has not been rolled back.',
            },
            'for': '15m',
            alert: 'KubeStatefulSetGenerationMismatch',
          },
          {
            expr: |||
              max without (revision) (
                kube_statefulset_status_current_revision{%(prefixedNamespaceSelector)s%(kubeStateMetricsSelector)s}
                  unless
                kube_statefulset_status_update_revision{%(prefixedNamespaceSelector)s%(kubeStateMetricsSelector)s}
              )
                *
              (
                kube_statefulset_replicas{%(prefixedNamespaceSelector)s%(kubeStateMetricsSelector)s}
                  !=
                kube_statefulset_status_replicas_updated{%(prefixedNamespaceSelector)s%(kubeStateMetricsSelector)s}
              )
            ||| % $._config,
            labels: {
              severity: 'critical',
            },
            annotations: {
              message: 'StatefulSet {{ $labels.namespace }}/{{ $labels.statefulset }} update has not been rolled out.',
            },
            'for': '15m',
            alert: 'KubeStatefulSetUpdateNotRolledOut',
          },
          {
            alert: 'KubeDaemonSetRolloutStuck',
            expr: |||
              kube_daemonset_status_number_ready{%(prefixedNamespaceSelector)s%(kubeStateMetricsSelector)s}
                /
              kube_daemonset_status_desired_number_scheduled{%(prefixedNamespaceSelector)s%(kubeStateMetricsSelector)s} < 1.00
            ||| % $._config,
            labels: {
              severity: 'critical',
            },
            annotations: {
              message: 'Only {{ $value | humanizePercentage }} of the desired Pods of DaemonSet {{ $labels.namespace }}/{{ $labels.daemonset }} are scheduled and ready.',
            },
            'for': '15m',
          },
          {
            alert: 'KubeDaemonSetNotScheduled',
            expr: |||
              kube_daemonset_status_desired_number_scheduled{%(prefixedNamespaceSelector)s%(kubeStateMetricsSelector)s}
                -
              kube_daemonset_status_current_number_scheduled{%(prefixedNamespaceSelector)s%(kubeStateMetricsSelector)s} > 0
            ||| % $._config,
            labels: {
              severity: 'warning',
            },
            annotations: {
              message: '{{ $value }} Pods of DaemonSet {{ $labels.namespace }}/{{ $labels.daemonset }} are not scheduled.',
            },
            'for': '10m',
          },
          {
            alert: 'KubeDaemonSetMisScheduled',
            expr: |||
              kube_daemonset_status_number_misscheduled{%(prefixedNamespaceSelector)s%(kubeStateMetricsSelector)s} > 0
            ||| % $._config,
            labels: {
              severity: 'warning',
            },
            annotations: {
              message: '{{ $value }} Pods of DaemonSet {{ $labels.namespace }}/{{ $labels.daemonset }} are running where they are not supposed to run.',
            },
            'for': '10m',
          },
          {
            alert: 'KubeCronJobRunning',
            expr: |||
              time() - kube_cronjob_next_schedule_time{%(prefixedNamespaceSelector)s%(kubeStateMetricsSelector)s} > 3600
            ||| % $._config,
            'for': '1h',
            labels: {
              severity: 'warning',
            },
            annotations: {
              message: 'CronJob {{ $labels.namespace }}/{{ $labels.cronjob }} is taking more than 1h to complete.',
            },
          },
          {
            alert: 'KubeJobCompletion',
            expr: |||
              kube_job_spec_completions{%(prefixedNamespaceSelector)s%(kubeStateMetricsSelector)s} - kube_job_status_succeeded{%(prefixedNamespaceSelector)s%(kubeStateMetricsSelector)s}  > 0
            ||| % $._config,
            'for': '1h',
            labels: {
              severity: 'warning',
            },
            annotations: {
              message: 'Job {{ $labels.namespace }}/{{ $labels.job_name }} is taking more than one hour to complete.',
            },
          },
          {
            alert: 'KubeJobFailed',
            expr: |||
              kube_job_failed{%(prefixedNamespaceSelector)s%(kubeStateMetricsSelector)s}  > 0
            ||| % $._config,
            'for': '15m',
            labels: {
              severity: 'warning',
            },
            annotations: {
              message: 'Job {{ $labels.namespace }}/{{ $labels.job_name }} failed to complete.',
            },
          },
          {
            expr: |||
              (kube_hpa_status_desired_replicas{%(prefixedNamespaceSelector)s%(kubeStateMetricsSelector)s}
                !=
              kube_hpa_status_current_replicas{%(prefixedNamespaceSelector)s%(kubeStateMetricsSelector)s})
                and
              changes(kube_hpa_status_current_replicas[15m]) == 0
            ||| % $._config,
            labels: {
              severity: 'warning',
            },
            annotations: {
              message: 'HPA {{ $labels.namespace }}/{{ $labels.hpa }} has not matched the desired number of replicas for longer than 15 minutes.',
            },
            'for': '15m',
            alert: 'KubeHpaReplicasMismatch',
          },
          {
            expr: |||
              kube_hpa_status_current_replicas{%(prefixedNamespaceSelector)s%(kubeStateMetricsSelector)s}
                ==
              kube_hpa_spec_max_replicas{%(prefixedNamespaceSelector)s%(kubeStateMetricsSelector)s}
            ||| % $._config,
            labels: {
              severity: 'warning',
            },
            annotations: {
              message: 'HPA {{ $labels.namespace }}/{{ $labels.hpa }} has been running at max replicas for longer than 15 minutes.',
            },
            'for': '15m',
            alert: 'KubeHpaMaxedOut',
          },
        ],
      },
    ],
  },
}
