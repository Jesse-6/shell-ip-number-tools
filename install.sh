#!/bin/bash

# Run as super user to install!

cp -a ip4tonum /usr/bin/
cp -a numtoip4 /usr/bin/
cp -a ip6tonum /usr/bin/
cp -a numtoip6 /usr/bin/
echo -ne '#!/bin/bash\n\n# Run as super user to uninstall!\n\nrm /usr/bin/ip4tonum\nrm /usr/bin/ip6tonum\nrm /usr/bin/numtoip4\nrm /usr/bin/numtoip6\n' > uninstall.sh
chmod +x uninstall.sh
