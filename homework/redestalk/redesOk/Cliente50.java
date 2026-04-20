package redesOk;

import java.util.Scanner;
import redesOk.TCPClient50;

class Cliente50 {
    TCPClient50 mTcpClient;
    Scanner sc;

    public static void main(String[] args) {
        Cliente50 objcli = new Cliente50();
        objcli.iniciar();
    }

    void iniciar() {
        new Thread(new Runnable() {
            @Override
            public void run() {
                mTcpClient = new TCPClient50("192.168.1.106",
                    new TCPClient50.OnMessageReceived() {
                        @Override
                        public void messageReceived(String message) {
                            ClienteRecibe(message);
                        }
                    }
                );
                mTcpClient.run();
            }
        }).start();

        String salir = "n";
        sc = new Scanner(System.in);
        System.out.println("Cliente bandera 01");
        while (!salir.equals("s")) {
            salir = sc.nextLine();
            ClienteEnvia(salir);
        }
        System.out.println("Cliente bandera 02");
    }

    void ClienteRecibe(String llego) {
        System.out.println("CLINTE50 El mensaje::" + llego);

        // --- Protocolo "envia N" ---
        if (llego != null && llego.startsWith("envia ")) {
            String[] partes = llego.split("\\s+");
            if (partes.length >= 2) {
                try {
                    int n = Integer.parseInt(partes[1]);
                    int resultado = calcular(n);
                    String respuesta = "resultado(N=" + n + ")=" + resultado;
                    System.out.println("CLINTE50 Calculado -> " + respuesta);
                    ClienteEnvia(respuesta);
                } catch (NumberFormatException e) {
                    System.out.println("CLINTE50 parametro no es entero: " + partes[1]);
                }
            }
        }
    }

    // Suma 1..N (Gauss). Cambia esta funcion si el profe pide otro calculo.
    int calcular(int n) {
        int suma = 0;
        for (int i = 1; i <= n; i++) suma += i;
        return suma;
    }

    void ClienteEnvia(String envia) {
        if (mTcpClient != null) {
            mTcpClient.sendMessage(envia);
        }
    }
}
