import json

# Carregar dados dos arquivos JSON
with open('computers_inventory.json', 'r') as f:
    computers_inventory = json.load(f)

with open('computers_check.json', 'r') as f:
    computers_check = json.load(f)

def find_differences(array1, array2):
    differences = []

    for obj1 in array1:
        name1 = obj1['name']
        found = False

        for obj2 in array2:
            if obj1['name'] == obj2['name']:
                if obj1 != obj2:
                    differences.append({
                        "name": name1,
                        "difference": {
                            "object1": obj1,
                            "object2": obj2
                        }
                    })
                found = True
                break

        if not found:
            differences.append({
                "name": name1,
                "difference": {
                    "object1": obj1,
                    "object2": None  # Indica que o objeto não foi encontrado em array2
                }
            })

    # Verificar objetos em array2 que não estão em array1
    for obj2 in array2:
        name2 = obj2['name']
        found = False

        for obj1 in array1:
            if obj2['name'] == obj1['name']:
                found = True
                break

        if not found:
            differences.append({
                "name": name2,
                "difference": {
                    "object1": None,  # Indica que o objeto não foi encontrado em array1
                    "object2": obj2
                }
            })

    return differences

# Encontrar diferenças entre computers_inventory e computers_check
differences = find_differences(computers_inventory, computers_check)

# Exibir as diferenças encontradas
print(json.dumps(differences, indent=2))

