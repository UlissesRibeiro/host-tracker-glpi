import os
import sys

def split_xml(file_path):
    # Verificar se o arquivo existe
    if not os.path.isfile(file_path):
        print(f"Arquivo {file_path} não encontrado.")
        return

    # Ler o conteúdo do arquivo original
    with open(file_path, 'r', encoding='utf-8') as file:
        content = file.read()

    # Dividir o conteúdo pelo cabeçalho XML
    documents = content.split('<?xml version="1.0" encoding="UTF-8"?>')

    # Remover o primeiro elemento, que será uma string vazia
    documents.pop(0)

    # Adicionar o cabeçalho XML de volta a cada documento e salvar em arquivos separados
    for i, doc in enumerate(documents):
        doc = '<?xml version="1.0" encoding="UTF-8"?>' + doc
        output_file = f'document_{i+1}.xml'
        with open(output_file, 'w', encoding='utf-8') as output:
            output.write(doc.strip())

    print(f"{len(documents)} arquivos XML gerados com sucesso.")

if __name__ == "__main__":
    # Verificar se o argumento foi passado
    if len(sys.argv) != 2:
        print("Uso: python3 splitxml.py <caminho_do_arquivo>")
        sys.exit(1)

    # Caminho para o arquivo original
    file_path = sys.argv[1]
    split_xml(file_path)


