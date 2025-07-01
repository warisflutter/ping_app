import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ping_app/file_path.dart';
import 'package:provider/provider.dart';

import '../util/ping_styles.dart';

class NumericListTile extends StatelessWidget {
  final String title;
  final IconData? iconData;
  final double? verticalH;
  final Color? iconColor, textColor;
  final TextEditingController controller;
  final String uid;
  const NumericListTile({super.key, required this.title, required this.controller, required this.uid,
  this.iconData, this.iconColor, this.textColor, this.verticalH});
  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: (iconData == null) ? Colors.white.withValues(alpha: .1) : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: (!context.isWatch || iconData == null) ? 16.0 : 2.0,
            vertical: verticalH ?? ((context.isWatch) ? 8.0 : 12.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (iconData != null)
                Padding(
                  padding: const EdgeInsets.only(right: 0),
                  child: Icon(
                    iconData,
                    size: (context.isWatch) ? PingStyles.watchIconSize : null,
                    color: iconColor,
                  ),
                ),
              Expanded(child: SizedBox(
                height: context.isWatch ? PingStyles.watchTextFieldHeight : 50,
                child: TextFormField(
                  controller: controller,
                  readOnly: true,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    label: Text(
                      title,
                      style: context.isWatch ? PingStyles.watchStyle : const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w400)
                    ),
                  ),
                  style: context.isWatch ? PingStyles.watchStyle : null,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  keyboardType: TextInputType.number,
                ),
              )),
              Column(
                children: [
                  GestureDetector(
                    onTap: () async{
                      var value = int.tryParse(controller.text) ?? 0;
                      value += 1;
                      controller.text = value.toString();
                      await AuthRepo.instance.updateDialogTimer(uid, value);
                    },
                    child: Icon(Icons.add, size: context.isWatch ? 12 : 18,),
                  ),
                  GestureDetector(
                    onTap: () async{
                      var value = int.tryParse(controller.text) ?? 0;
                      if(value > 0){
                        value -= 1;
                        controller.text = value.toString();
                        await AuthRepo.instance.updateDialogTimer(uid, value);
                      }
                    },
                    child: Icon(Icons.minimize, size: context.isWatch ? 12 : 18,),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
