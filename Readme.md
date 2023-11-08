## Development

1. Modify/extend chart.
2. Adjust documentation.
3. Adjust changelog.
4. `helm package -d docs ./disc-generic`
5. `helm repo index --url https://ou-disc.github.io/helmcharts ./docs`
