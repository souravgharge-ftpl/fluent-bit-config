function clean_log(tag, timestamp, record)
    if record["message"] then
        local message = record["message"]
        -- Remove stdout F prefix
        message = string.gsub(message, "%f[%a]stdout%s+F%s+", "")
        -- Remove timestamp prefix
        message = string.gsub(message, "^%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d:%d%d%.%d+Z%s+", "")
        
        local cleaned_lines = {}
        for line in string.gmatch(message, "[^\n]+") do
            local cleaned_line = string.gsub(line, "^%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d:%d%d%.%d+Z%s+", "")
            table.insert(cleaned_lines, cleaned_line)
        end
        record["message"] = table.concat(cleaned_lines, "\n")
    end
    return 1, timestamp, record
end
