import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

class DenominationChangeModalBottomSheet extends StatefulWidget {
  final settingsNotifier;

  const DenominationChangeModalBottomSheet({Key? key, required this.settingsNotifier}) : super(key: key);

  @override
  _DenominationChangeModalBottomSheetState createState() => _DenominationChangeModalBottomSheetState();
}

class _DenominationChangeModalBottomSheetState extends State<DenominationChangeModalBottomSheet> {
  String selectedButton = 'currency';

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final titleFontSize = screenHeight * 0.03;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), // Adjust for keyboard if necessary
      decoration: BoxDecoration(
        color: Colors.black, // Background color for the modal
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Ensure the column only takes up the space it needs
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: ToggleButtons(
              isSelected: [
                selectedButton == 'currency',
                selectedButton == 'denomination',
              ],
              onPressed: (int index) {
                setState(() {
                  selectedButton = index == 0 ? 'currency' : 'denomination';
                });
              },
              borderRadius: BorderRadius.circular(0), // No rounded corners
              fillColor: Colors.transparent, // No fill color
              renderBorder: false, // Disable default borders
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: selectedButton == 'currency'
                              ? Colors.deepOrange
                              : Colors.transparent, // Orange if selected, transparent if not
                          width: 2.0, // Border width
                        ),
                      ),
                    ),
                    child: Text(
                      'Currency',
                      style: TextStyle(
                        fontSize: titleFontSize * 0.7,
                        color: Colors.white, // Text color
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: selectedButton == 'denomination'
                              ? Colors.deepOrange
                              : Colors.transparent, // Orange if selected, transparent if not
                          width: 2.0, // Border width
                        ),
                      ),
                    ),
                    child: Text(
                      'Bitcoin Unit',
                      style: TextStyle(
                        fontSize: titleFontSize * 0.7,
                        color: Colors.white, // Text color
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: screenHeight * 0.4, // Maximum height of the modal
              ),
              child: selectedButton == 'currency'
                  ? _buildCurrencyList(context, widget.settingsNotifier)
                  : _buildBitcoinFormatList(context, widget.settingsNotifier),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyList(BuildContext context, settingsNotifier) {
    return ListView(
      shrinkWrap: true, // Shrink to fit the content
      children: [
        ListTile(
          leading: Flag(Flags.brazil),
          title: const Text('BRL', style: TextStyle(color: Colors.white)),
          onTap: () {
            settingsNotifier.setCurrency('BRL');
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: Flag(Flags.united_states_of_america),
          title: const Text('USD', style: TextStyle(color: Colors.white)),
          onTap: () {
            settingsNotifier.setCurrency('USD');
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: Flag(Flags.european_union),
          title: const Text('EUR', style: TextStyle(color: Colors.white)),
          onTap: () {
            settingsNotifier.setCurrency('EUR');
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  Widget _buildBitcoinFormatList(BuildContext context, settingsNotifier) {
    return ListView(
      shrinkWrap: true, // Shrink to fit the content
      children: [
        ListTile(
          leading: const Text('₿', style: TextStyle(color: Colors.white, fontSize: 24)),
          title: const Text('BTC', style: TextStyle(color: Colors.white)),
          onTap: () {
            settingsNotifier.setBtcFormat('BTC');
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: const Text('sats', style: TextStyle(color: Colors.white, fontSize: 24)),
          title: const Text('Satoshi', style: TextStyle(color: Colors.white)),
          onTap: () {
            settingsNotifier.setBtcFormat('sats');
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
