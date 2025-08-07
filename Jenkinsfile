def csvFilesChanged = []

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

        stage('Detect Changed CSV Files') {
            steps {
                script {
                    csvFilesChanged = sh(
                        script: "git diff --name-only HEAD HEAD~1 | grep '.csv' || true",
                        returnStdout: true
                    ).trim().split('\n').findAll { it.endsWith(".csv") }

                    echo "Changed CSV files: ${csvFilesChanged}"
                }
            }
        }

        stage('Generate Configs Only for Changed CSVs') {
            when {
                expression { csvFilesChanged && csvFilesChanged.size() > 0 }
            }
            steps {
                sshagent([env.SSH_KEY]) {
                    script {
                        def inputTemplate  = readFile('common/template/fluentbit_input_template.conf')
                        def filterTemplate = readFile('common/template/fluentbit_filter_template.conf')
                        def outputTemplate = readFile('common/template/fluentbit_output_template.conf')

                        csvFilesChanged.each { csvPath ->
                            def productName = csvPath.tokenize('/')[0] // e.g., 'connecthub'
                            def lines = readFile(csvPath).split('\n')

                            def combinedInput = ""
                            def combinedFilter = "@include /fluent-bit/etc/includes/common/fluent-bit-filter.conf\n\n"
                            def combinedOutput = ""

                            lines.eachWithIndex { line, idx ->
                                if (idx == 0 || line.startsWith("#")) return
                                def (deployment, index, firstline, multiline) = line.split(",", -1)
                                deployment = deployment.trim()
                                index      = index.trim()
                                firstline  = firstline?.trim() ?: ""
                                multiline  = multiline?.trim() ?: ""

                                def parserLine = ""
                                if (firstline)  parserLine += "    Parser_Firstline    ${firstline}\n"
                                if (multiline)  parserLine += "    Parser_N            ${multiline}\n"

                                combinedInput += inputTemplate
                                    .replace("{{DEPLOYMENT}}", deployment)
                                    .replace("{{PARSER_LINE}}", parserLine) + "\n"

                                combinedOutput += outputTemplate
                                    .replace("{{DEPLOYMENT}}", deployment)
                                    .replace("{{INDEX}}", index) + "\n"
                            }

                            def finalConf = combinedInput + combinedFilter + combinedOutput
                            def outputFileName = "${productName}-fluentbit_uat.conf"
                            def outputPath = "${productName}/${outputFileName}"

                            writeFile file: outputPath, text: finalConf
                            echo "Generated config for ${productName}:\n" + finalConf

                            // SCP to UAT server
                            sh """
                                scp -o StrictHostKeyChecking=no ${outputPath} fluent-bit-user@${UAT_SERVER}:/home/fluent-bit-user/opensearch-bkp_22JAN25/config/${productName}/

                                ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -o ServerAliveCountMax=5 fluent-bit-user@${UAT_SERVER} <<'EOF'
                                    ls -ltr /home/fluent-bit-user/opensearch-bkp_22JAN25/config/${productName}/${outputFileName}
EOF
                            """
                        }
                    }
                }
            }
        }
    }
}
