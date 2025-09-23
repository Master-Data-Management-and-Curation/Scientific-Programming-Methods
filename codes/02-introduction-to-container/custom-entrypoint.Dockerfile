FROM ubuntu:22.04

RUN cat > /custom_script.sh << 'EOF'
#!/bin/bash
echo "This is a custom script."

echo "Arguments passed: $@"
for arg in "$@"; do
echo "Argument: $arg"
done
EOF

RUN chmod +x /custom_script.sh

ENTRYPOINT ["/custom_script.sh"]
