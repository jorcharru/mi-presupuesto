import 'package:flutter/material.dart';
import 'presupuesto_colombia_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi Presupuesto',
      debugShowCheckedModeBanner: false, // Elimina el banner de depuración
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Cambiamos el AppBar para tener un banner con tres franjas de colores
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(120), // Aumentamos la altura del banner
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.yellow, Colors.blue, Colors.red], // Amarillo, azul, rojo
              stops: [0.5, 0.75, 1], // Proporciones de las franjas (amarillo más grande)
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Align(
            alignment: Alignment.bottomCenter, // Alinear el contenido en la parte inferior
            child: Padding(
              padding: EdgeInsets.only(bottom: 16), // Espacio en la parte inferior
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 16), // Espacio a la izquierda
                    child: Text(
                      'Mi Presupuesto',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // Cambiamos el color para que sea visible
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: 16), // Espacio a la derecha
                    child: Text(
                      'Jorge Charrupi',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.black, // Cambiamos el color para que sea visible
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Botón con un diseño más bonito
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PresupuestoColombiaScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan, // Color del botón
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                textStyle: TextStyle(fontSize: 20),
              ),
              child: Text('VER PRESUPUESTO'),
            ),
          ],
        ),
      ),
    );
  }
}