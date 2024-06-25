<?php
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;
use PHPMailer\PHPMailer\SMTP;

require 'vendor/autoload.php';

// Função para verificar se o arquivo contém "Agent_Desconectado"
function containsAgentDesconectado($filePath)
{
    if (file_exists($filePath)) {
        $content = file_get_contents($filePath);
        return strpos($content, 'Inativo') !== false;
    }
    return false;
}

// Caminho do arquivo
$filePath = '/vox/phpmailer/computers_inativo.txt';

// Verifica se o arquivo existe e contém "Agent_Desconectado"
if (containsAgentDesconectado($filePath)) {
    // Configurações do PHPMailer
    $mail = new PHPMailer(true);

    try {
        $mail->isSMTP();
        include 'smtp_conf.php';

        $mail->CharSet = 'UTF-8';
        $mail->setFrom('ulisses@voxtecnologia.com.br', 'Ulisses');
        $mail->addAddress('ulisses@voxtecnologia.com.br');
        $mail->addAttachment($filePath);

        $mail->isHTML(true);
        $mail->CharSet = 'UTF-8';
        $mail->Subject = "Alerta: Agent Inativo";

        // Corpo do e-mail
        $mail->Body = '<html><body style="color: red;font-family: verdana,sans-serif;">';
        $mail->Body .= "<p>ALERTA: O arquivo $filePath contém 'Agent Inativo'.</p>";
        $mail->Body .= '</body></html>';

        // Envia o e-mail
        $mail->send();
        echo "E-mail enviado informando sobre o Agent Inativos!\n";
    } catch (Exception $e) {
        echo "Erro ao enviar mensagem: {$mail->ErrorInfo}\n";
    }
} else {
    echo "O arquivo não existe ou não contém 'Agent Inativo'.\n";
}
?>

