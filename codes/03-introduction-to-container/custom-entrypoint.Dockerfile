FROM ubuntu:22.04

RUN printf '#!/bin/bash\necho "This is a custom script."\n\necho "Arguments passed: $@"\nfor arg in "$@"; do\necho "Argument: $arg"\ndone\n' > /custom_script.sh

RUN chmod +x /custom_script.sh

ENTRYPOINT ["/custom_script.sh"]
