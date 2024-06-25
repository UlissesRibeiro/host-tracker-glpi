#!/bin/bash    
curl -X POST \
-H 'Content-Type: application/json' \
-H "Authorization: user_token A8nTRB3GjwmAVdANpWNujavN8D0fObCtChgg11cG" \
-H "App-Token: b7GsHjO6spac0nKHXzq8cxyGe8YjkUGvpi5mTaPI" \
-d '{
   "login_name": "glpi",
   "login_password": "m4qdesenv16"
   }' \
'http://10.0.10.224:8030/apirest.php/initSession?get_full_session=true' |jq '{session_token: .session_token}'
