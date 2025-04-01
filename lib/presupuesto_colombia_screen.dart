import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PresupuestoColombiaScreen extends StatefulWidget {
  @override
  _PresupuestoColombiaScreenState createState() =>
      _PresupuestoColombiaScreenState();
}

class _PresupuestoColombiaScreenState
    extends State<PresupuestoColombiaScreen> {
  List<Map<String, dynamic>> data = [];
  double totalPesos = 0;
  double totalDolar = 0;
  double pagoPesos = 0;
  double pagoDolar = 0;
  double pendientePesos = 0;
  double pendienteDolar = 0;
  double precioDolar = 1;
  String _selectedMonth = 'Enero'; // Mes seleccionado por defecto
  String _selectedFilter = 'Todo'; // Filtro seleccionado por defecto
  String _selectedEstadoFilter = 'Todo'; // Filtro de estado seleccionado por defecto
  final List<String> _months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  // Controladores para los campos de texto
  List<TextEditingController> _conceptoControllers = [];
  List<TextEditingController> _valorControllers = [];
  TextEditingController _precioDolarController = TextEditingController();
  TextEditingController _disponibleController = TextEditingController();
  double faltante = 0;

  // Valores predeterminados para la columna "Concepto"
  final List<String> _defaultConceptos = [
    "Daniel", "Pensión Jenny", "Pensión Jorge", "Miusty", "Youtube", "Cuota Apto", "Servicios Apto",
    "Admon Apto", "Celular", "Icetex", "Arrendo Cartagena", "Servicios Cartagena",
    "Keren 1 Q.", "Keren 2 Q.", "Carro", "Seguros Carros", "Tarjetas", "Gasolina", "Seguro Vida", "lavadero", "Spotify y Otros"
  ];

  // Valores predeterminados para la columna "Valor"
  final List<String> _defaultValores = [
    "350000", "450000", "230000", "180000", "50000", "2450000", "100000", "300000", "100000", "280000",
    "700000", "150000", "350000", "350000", "480", "280", "120", "300", "40", "30", "30"
  ];

  @override
  void initState() {
    super.initState();
    _loadLastSelectedMonth();
    _loadData();
  }

  void _loadLastSelectedMonth() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastMonth = prefs.getString('last_selected_month');
    if (lastMonth != null) {
      setState(() {
        _selectedMonth = lastMonth;
      });
      _loadData(); // Cargar los datos del mes seleccionado inmediatamente
    }
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString('colombia_data_$_selectedMonth');
    double? savedPrecioDolar = prefs.getDouble('precio_dolar_$_selectedMonth');
    double? savedDisponible = prefs.getDouble('disponible_$_selectedMonth');
    double? savedFaltante = prefs.getDouble('faltante_$_selectedMonth');

    if (savedData != null) {
      setState(() {
        data = List<Map<String, dynamic>>.from(json.decode(savedData));
        precioDolar = savedPrecioDolar ?? 1;
        _initializeControllers(); // Inicializar controladores con los datos cargados
        calcularTotales();

        // Cargar la información de "Disponible" y "Faltante"
        _disponibleController.text = savedDisponible?.toString() ?? '0';
        faltante = savedFaltante ?? 0;
      });
    } else {
      setState(() {
        data = List.generate(_defaultConceptos.length, (index) {
          return {
            'concepto': _defaultConceptos[index],
            'valor': double.tryParse(_defaultValores[index]) ?? 0,
            'verf': false,
            'estado': 'PENDIENTE',
            'valorDolar': null,
            'id': 'Col', // Valor predeterminado para la columna "ID"
          };
        });
        _initializeControllers(); // Inicializar controladores con datos predeterminados
      });
    }
  }

  void _initializeControllers() {
    _conceptoControllers = data.map((item) {
      return TextEditingController(text: item['concepto']?.toString() ?? '');
    }).toList();

    _valorControllers = data.map((item) {
      // Formatear el valor predeterminado con el símbolo "$" y el formato de miles
      return TextEditingController(text: formatoMoneda(item['valor'] ?? 0));
    }).toList();

    _precioDolarController = TextEditingController(text: precioDolar.toString());
    _disponibleController = TextEditingController();
  }

  void _saveData() async {
    // Actualizar la lista `data` con los valores de los controladores
    for (int i = 0; i < data.length; i++) {
      data[i]['concepto'] = _conceptoControllers[i].text;
      // Eliminar el símbolo "$" y los puntos antes de guardar el valor
      String valorSinFormato = _valorControllers[i].text.replaceAll('\$', '').replaceAll('.', '');
      data[i]['valor'] = double.tryParse(valorSinFormato) ?? 0;
    }

    precioDolar = double.tryParse(_precioDolarController.text) ?? 1;

    // Guardar la información de "Disponible", "Pendiente" y "Faltante"
    double disponible = double.tryParse(_disponibleController.text) ?? 0;
    double faltante = pendienteDolar - disponible;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('colombia_data_$_selectedMonth', json.encode(data));
    prefs.setDouble('precio_dolar_$_selectedMonth', precioDolar);
    prefs.setDouble('disponible_$_selectedMonth', disponible);
    prefs.setDouble('faltante_$_selectedMonth', faltante);
    prefs.setString('last_selected_month', _selectedMonth); // Guardar el último mes seleccionado

    // Actualizar la pantalla
    setState(() {
      calcularTotales();
    });
  }

  void calcularTotales() {
    setState(() {
      // Calcular totalPesos: suma de valores con "ID" igual a "Col"
      totalPesos = data
          .where((item) => item['id'] == 'Col')
          .fold(0, (sum, item) => sum + (item['valor'] ?? 0));

      // Calcular totalDolar: suma de todos los valores en la columna "Dolar"
      totalDolar = data.fold(0, (sum, item) {
        double valorDolar = item['id'] == 'Col' ? (item['valor'] ?? 0) / precioDolar : (item['valor'] ?? 0);
        return sum + valorDolar;
      });

      // Calcular pagoPesos: suma de valores con "ID" igual a "Col" y estado "PAGO"
      pagoPesos = data
          .where((item) => item['id'] == 'Col' && item['estado'] == 'PAGO')
          .fold(0, (sum, item) => sum + (item['valor'] ?? 0));

      // Calcular pagoDolar: suma de valores en la columna "Dolar" con estado "PAGO"
      pagoDolar = data
          .where((item) => item['estado'] == 'PAGO')
          .fold(0, (sum, item) {
        double valorDolar = item['id'] == 'Col' ? (item['valor'] ?? 0) / precioDolar : (item['valor'] ?? 0);
        return sum + valorDolar;
      });

      // Calcular pendientePesos: suma de valores con "ID" igual a "Col" y estado "PENDIENTE"
      pendientePesos = data
          .where((item) => item['id'] == 'Col' && item['estado'] == 'PENDIENTE')
          .fold(0, (sum, item) => sum + (item['valor'] ?? 0));

      // Calcular pendienteDolar: suma de valores en la columna "Dolar" con estado "PENDIENTE"
      pendienteDolar = data
          .where((item) => item['estado'] == 'PENDIENTE')
          .fold(0, (sum, item) {
        double valorDolar = item['id'] == 'Col' ? (item['valor'] ?? 0) / precioDolar : (item['valor'] ?? 0);
        return sum + valorDolar;
      });

      // Calcular el faltante
      double disponible = double.tryParse(_disponibleController.text) ?? 0;
      faltante = pendienteDolar - disponible;
    });
  }

  String formatoMoneda(double valor) {
    if (valor == null) return '';
    final formatter = NumberFormat('#,##0', 'es_CO'); // Sin decimales
    return '\$${formatter.format(valor)}';
  }

  List<Map<String, dynamic>> getFilteredData() {
    List<Map<String, dynamic>> filteredData = data;

    // Aplicar filtro de "ID"
    if (_selectedFilter == 'Col') {
      filteredData = filteredData.where((item) => item['id'] == 'Col').toList();
    } else if (_selectedFilter == 'Usa') {
      filteredData = filteredData.where((item) => item['id'] == 'Usa').toList();
    }

    // Aplicar filtro de estado
    if (_selectedEstadoFilter == 'Pago') {
      filteredData = filteredData.where((item) => item['estado'] == 'PAGO').toList();
    } else if (_selectedEstadoFilter == 'Pendiente') {
      filteredData = filteredData.where((item) => item['estado'] == 'PENDIENTE').toList();
    }

    return filteredData;
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredData = getFilteredData();

    // Calcular totales de los datos visibles (filtrados)
    double totalValorVisible = filteredData
        .where((item) => item['id'] == 'Col')  // Solo sumar si ID == 'Col'
        .fold(0, (sum, item) => sum + (item['valor'] ?? 0));
    double totalDolarVisible = filteredData.fold(0, (sum, item) {
      double valorDolar = item['id'] == 'Col' ? (item['valor'] ?? 0) / precioDolar : (item['valor'] ?? 0);
      return sum + valorDolar;
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('MI PRESUPUESTO'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lista desplegable para seleccionar el mes
              DropdownButton<String>(
                value: _selectedMonth,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedMonth = newValue!;
                    _loadData(); // Cargar datos del mes seleccionado
                  });
                },
                items: _months.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              // Filtros adicionales
              Row(
                children: [
                  DropdownButton<String>(
                    value: _selectedFilter,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedFilter = newValue!;
                      });
                    },
                    items: ['Todo', 'Col', 'Usa'].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _selectedEstadoFilter,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedEstadoFilter = newValue!;
                      });
                    },
                    items: ['Todo', 'Pago', 'Pendiente'].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
              SizedBox(height: 20),
              // Precio del dólar con fondo azul claro
              Container(
                color: Colors.blue[50], // Color azul claro
                padding: EdgeInsets.all(8),
                child: Row(
                  children: [
                    Text('Precio del dólar:'),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _precioDolarController,
                        keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                        onChanged: (value) {
                          setState(() {
                            precioDolar =
                            value.isEmpty ? 1 : double.tryParse(value) ?? 1;
                            _saveData(); // Guardar automáticamente
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              // Cuadro de datos con bordes
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2),
                    color: Colors.yellow[100],
                  ),
                  child: Table(
                    defaultColumnWidth: IntrinsicColumnWidth(), // Ajusta el ancho al contenido
                    border: TableBorder(
                      verticalInside: BorderSide(width: 2, color: Colors.black),
                      horizontalInside: BorderSide(width: 1, color: Colors.black),
                    ),
                    children: [
                      // Encabezados
                      TableRow(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8), // Espacio horizontal
                            child: Text('CONCEPTO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), // Tamaño de fuente 14
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8), // Espacio horizontal
                            child: Text('VALOR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), // Tamaño de fuente 14
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8), // Espacio horizontal
                            child: Center( // Centrar el texto
                              child: Text('DOLAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), // Tamaño de fuente 14
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8), // Espacio horizontal
                            child: Text('VERF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), // Tamaño de fuente 14
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8), // Espacio horizontal
                            child: Text('ESTADO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), // Tamaño de fuente 12
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8), // Espacio horizontal
                            child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), // Tamaño de fuente 14
                          ),
                        ],
                      ),
                      // Filas de datos
                      ...filteredData.map((item) {
                        int index = data.indexOf(item); // Obtener el índice correcto en la lista original
                        return TableRow(
                          decoration: BoxDecoration(
                            color: item['id'] == 'Usa' ? Colors.blue[100] : null,
                          ),
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8), // Espacio horizontal
                              child: TextFormField(
                                controller: _conceptoControllers[index], // Usar el índice correcto
                                onChanged: (value) {
                                  setState(() {
                                    item['concepto'] = value;
                                    _saveData(); // Guardar automáticamente
                                  });
                                },
                                style: TextStyle(
                                  color: item['verf'] == false ? Colors.red : null,
                                  fontSize: 14, // Tamaño de fuente 14
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8), // Espacio horizontal
                              child: TextFormField(
                                controller: _valorControllers[index], // Usar el índice correcto
                                keyboardType: TextInputType.number,
                                style: TextStyle(fontSize: 14), // Tamaño de fuente 14
                                onChanged: (value) {
                                  // Formatear el valor ingresado
                                  String formattedValue = value.replaceAll('\$', '').replaceAll('.', '');
                                  double parsedValue = double.tryParse(formattedValue) ?? 0;
                                  _valorControllers[index].text = formatoMoneda(parsedValue);
                                  item['valor'] = parsedValue;
                                  calcularTotales();
                                  _saveData(); // Guardar automáticamente
                                },
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8), // Espacio horizontal
                              child: Center( // Centrar el texto
                                child: Text(
                                  item['id'] == 'Col'
                                      ? '\$${(item['valor']! / precioDolar).toStringAsFixed(2)}'
                                      : '\$${item['valor']?.toStringAsFixed(2) ?? '0.00'}',
                                  style: TextStyle(fontSize: 14), // Tamaño de fuente 14
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8), // Espacio horizontal
                              child: Checkbox(
                                value: item['verf'] ?? false,
                                onChanged: (value) {
                                  setState(() {
                                    item['verf'] = value ?? false;
                                    item['estado'] =
                                    (value ?? false) ? 'PAGO' : 'PENDIENTE';
                                    calcularTotales();
                                    _saveData(); // Guardar automáticamente
                                  });
                                },
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8), // Espacio horizontal
                              child: Text(
                                item['estado'] ?? 'PENDIENTE',
                                style: TextStyle(fontSize: 12), // Tamaño de fuente 12
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8), // Espacio horizontal
                              child: DropdownButton<String>(
                                value: item['id'],
                                onChanged: (String? newValue) {
                                  setState(() {
                                    item['id'] = newValue!;
                                    _saveData(); // Guardar automáticamente
                                  });
                                },
                                items: ['Col', 'Usa'].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value, style: TextStyle(fontSize: 14)), // Tamaño de fuente 14
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                      // Fila de totales de los datos visibles
                      TableRow(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('TOTAL VISIBLE', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(formatoMoneda(totalValorVisible), style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Center(
                              child: Text('\$${totalDolarVisible.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(''),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(''),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(''),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Botones para agregar y eliminar línea
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        data.add({
                          'concepto': '',
                          'valor': 0, // Valor inicial no nulo
                          'verf': false,
                          'estado': 'PENDIENTE',
                          'valorDolar': null,
                          'id': 'Col', // Valor predeterminado para la columna "ID"
                        });
                        _conceptoControllers.add(TextEditingController());
                        _valorControllers.add(TextEditingController(text: formatoMoneda(0))); // Valor inicial no nulo
                        _saveData(); // Guardar automáticamente
                      });
                    },
                    child: Text('Agregar línea'),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      if (data.length > 4) {
                        setState(() {
                          data.removeLast();
                          _conceptoControllers.removeLast();
                          _valorControllers.removeLast();
                          calcularTotales();
                          _saveData(); // Guardar automáticamente
                        });
                      }
                    },
                    child: Text('Eliminar última línea'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              // Cuadro de totales con borde rojo claro y centrado
              Center(
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red, width: 2),
                    color: Colors.red[50], // Color más suave
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: SizedBox()),
                          Expanded(child: Text('PESOS', style: TextStyle(fontSize: 14))), // Tamaño de fuente 14
                          Expanded(child: Text('DOLAR', style: TextStyle(fontSize: 14))), // Tamaño de fuente 14
                        ],
                      ),
                      Divider(),
                      Row(
                        children: [
                          Expanded(child: Text('TOTAL', style: TextStyle(fontSize: 14))), // Tamaño de fuente 14
                          Expanded(child: Text(formatoMoneda(totalPesos), style: TextStyle(fontSize: 14))), // Tamaño de fuente 14
                          Expanded(child: Text('\$${totalDolar.toStringAsFixed(2)}', style: TextStyle(fontSize: 14))), // Tamaño de fuente 14
                        ],
                      ),
                      Divider(),
                      Row(
                        children: [
                          Expanded(child: Text('PAGO', style: TextStyle(fontSize: 14))), // Tamaño de fuente 14
                          Expanded(child: Text(formatoMoneda(pagoPesos), style: TextStyle(fontSize: 14))), // Tamaño de fuente 14
                          Expanded(child: Text('\$${pagoDolar.toStringAsFixed(2)}', style: TextStyle(fontSize: 14))), // Tamaño de fuente 14
                        ],
                      ),
                      Divider(),
                      Row(
                        children: [
                          Expanded(child: Text('PENDIENTE', style: TextStyle(fontSize: 14))), // Tamaño de fuente 14
                          Expanded(
                            child: Text(
                              formatoMoneda(pendientePesos),
                              style: TextStyle(
                                fontSize: 14, // Tamaño de fuente 14
                                color: pendientePesos != 0 ? Colors.red : null, // Resaltar si es diferente a 0
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '\$${pendienteDolar.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14, // Tamaño de fuente 14
                                color: pendienteDolar != 0 ? Colors.red : null, // Resaltar si es diferente a 0
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Nueva fila con "Disponible", "Pendiente" y "Faltante"
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 1),
                  color: Colors.grey[200], // Color suave
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _disponibleController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Disponible',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            calcularTotales();
                            _saveData(); // Guardar automáticamente
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pendiente: \$${pendienteDolar.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: pendienteDolar != 0 ? Colors.red : null, // Resaltar si es diferente a 0
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Faltante: \$${faltante.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: faltante != 0 ? FontWeight.bold : FontWeight.normal, // Resaltar en negrita
                          color: faltante != 0 ? Colors.red : null, // Resaltar en rojo
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}