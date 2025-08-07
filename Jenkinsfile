//Using CSV file
def configList = []

pipeline {
    agent any

    environment {
        UAT_SERVER = '13.235.152.196'
        SSH_KEY = 'fluent-bit-user'
    }

    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout') {
            steps {
                git(
                    url: 'https://github.com/souravgharge-ftpl/fluent-bit-config.git',
                    branch: 'main',
                    credentialsId: 'sourav-github-token'
                )
            }
        }

        stage('Build Fluent Bit Configs') {
            steps {
                sshagent([env.SSH_KEY]) {
                    script {
                        // Read templates
                        def input_template  = readFile('common/template/fluentbit_input_template.conf')
                        def filter_template = readFile('common/template/fluentbit_filter_template.conf')
                        def output_template = readFile('common/template/fluentbit_output_template.conf')

                        // Read and parse CSV
                        def content = readFile('connecthub/fluentbit_config_uat.csv').split('\n')

                        def combinedInput  = ""
                        def combinedFilter = "@include /fluent-bit/etc/includes/common/fluent-bit-filter.conf" + "\n\n"
                        def combinedOutput = ""

                        content.eachWithIndex { line, idx ->
                            if (idx == 0 || line.startsWith("#")) return
                            def (deployment, index, firstline, multiline) = line.split(",", -1)
                            deployment = deployment.trim()
                            index      = index.trim()
                            firstline  = firstline?.trim() ?: ""
                            multiline  = multiline?.trim() ?: ""
                            def parserLine = ''
                            if (firstline) {
                                parserLine += "    Parser_Firstline    ${firstline}\n"
                            }
                            if (multiline) {
                                parserLine += "    Parser_N            ${multiline}\n"
                            }

                            // Replace placeholders
                            combinedInput += input_template
                                .replace("{{DEPLOYMENT}}", deployment)
                                .replace("{{PARSER_LINE}}", parserLine) + "\n" 

                            combinedOutput += output_template
                                .replace("{{DEPLOYMENT}}", deployment)
                                .replace("{{INDEX}}", index) + "\n"
                        }

                        // Combine all parts into a final config
                        def finalConf = combinedInput + combinedFilter + combinedOutput
                        def outputFile = "connecthub/connecthub-fluentbit_uat.conf"

                        writeFile file: outputFile, text: finalConf

                        echo "Generated combined config:\n" + readFile(outputFile)

                        // SCP to UAT server
                        sh """
                            scp -o StrictHostKeyChecking=no ${outputFile} fluent-bit-user@${UAT_SERVER}:/home/fluent-bit-user/opensearch-bkp_22JAN25/config/connecthub

                            ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -o ServerAliveCountMax=5 fluent-bit-user@${UAT_SERVER} <<'EOF'
                                ls -ltr /home/fluent-bit-user/opensearch-bkp_22JAN25/config/${outputFile}
EOF
                        """
                    }
                }
            }
        }

    }
}
