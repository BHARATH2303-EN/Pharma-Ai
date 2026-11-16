import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

void main() => runApp(const PharmaAIApp());

class PharmaAIApp extends StatelessWidget {
  const PharmaAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF087E8B);
    return MaterialApp(
      title: 'PharmaAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F8FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F8FA),
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(color: Color(0xFF15343A), fontSize: 21, fontWeight: FontWeight.bold),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  final pages = const [
    DashboardPage(), PrescriptionPage(), DrugInfoPage(), InteractionPage(),
    CounsellingPage(), AdrPage(), AdherencePage(), AssistantPage(),
  ];
  final labels = const ['Home', 'Prescription', 'Drug info', 'Interactions', 'Counselling', 'ADR reports', 'Adherence', 'AI assistant'];
  final icons = const [
    Icons.dashboard_rounded, Icons.document_scanner_outlined, Icons.medication_outlined,
    Icons.compare_arrows_rounded, Icons.chat_bubble_outline, Icons.health_and_safety_outlined,
    Icons.alarm_outlined, Icons.smart_toy_outlined
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.local_pharmacy_rounded, color: Colors.white)),
          const SizedBox(width: 10),
          const Text('PharmaAI'),
        ]),
        actions: [
          Padding(padding: const EdgeInsets.only(right: 14), child: Icon(Icons.circle, size: 10, color: Colors.green.shade600)),
        ],
      ),
      body: Row(children: [
        if (MediaQuery.of(context).size.width >= 850)
          NavigationRail(
            selectedIndex: index, onDestinationSelected: (v) => setState(() => index = v),
            labelType: NavigationRailLabelType.all,
            destinations: List.generate(labels.length, (i) => NavigationRailDestination(icon: Icon(icons[i]), label: Text(labels[i]))),
          ),
        Expanded(child: IndexedStack(index: index, children: pages)),
      ]),
      bottomNavigationBar: MediaQuery.of(context).size.width < 850
          ? NavigationBar(
              selectedIndex: index > 4 ? 0 : index,
              onDestinationSelected: (v) {
                if (v == 4) {
                  showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(leading: const Icon(Icons.chat_bubble_outline), title: const Text('Patient Counselling'), onTap: () { Navigator.pop(ctx); setState(() => index = 4); }),
                      ListTile(leading: const Icon(Icons.health_and_safety_outlined), title: const Text('ADR Reporting'), onTap: () { Navigator.pop(ctx); setState(() => index = 5); }),
                      ListTile(leading: const Icon(Icons.alarm_outlined), title: const Text('Medication Adherence'), onTap: () { Navigator.pop(ctx); setState(() => index = 6); }),
                      ListTile(leading: const Icon(Icons.smart_toy_outlined), title: const Text('AI Assistant'), onTap: () { Navigator.pop(ctx); setState(() => index = 7); }),
                    ],
                  )));
                } else {
                  setState(() => index = v);
                }
              },
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.document_scanner_outlined), label: 'Rx'),
                NavigationDestination(icon: Icon(Icons.medication_outlined), label: 'Drugs'),
                NavigationDestination(icon: Icon(Icons.compare_arrows), label: 'Check'),
                NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
              ],
            )
          : null,
      floatingActionButton: MediaQuery.of(context).size.width < 850 && index == 0
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => index = 7),
              icon: const Icon(Icons.smart_toy_outlined), label: const Text('Ask PharmaAI'))
          : null,
    );
  }
}

class PageFrame extends StatelessWidget {
  final String title, subtitle;
  final Widget child;
  const PageFrame({super.key, required this.title, required this.subtitle, required this.child});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1000), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF173B42))),
        const SizedBox(height: 5), Text(subtitle, style: TextStyle(color: Colors.blueGrey.shade600)),
        const SizedBox(height: 22), child,
      ],
    ))),
  );
}

class Panel extends StatelessWidget {
  final Widget child;
  const Panel({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE7EEF0))),
    child: child,
  );
}

Widget field(TextEditingController c, String label, {int lines = 1, String? hint}) =>
  TextField(controller: c, maxLines: lines, decoration: InputDecoration(labelText: label, hintText: hint));

Widget actionButton(BuildContext context, String text, VoidCallback onTap, {IconData icon = Icons.arrow_forward}) =>
  SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: onTap, icon: Icon(icon), label: Text(text), style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15))));

void showError(BuildContext context, Object e) => ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade700));

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}
class _DashboardPageState extends State<DashboardPage> {
  String status = 'Checking backend…';
  @override
  void initState() { super.initState(); _check(); }
  Future<void> _check() async {
    try { await ApiService.get('/health'); if (mounted) setState(() => status = 'Backend connected'); }
    catch (_) { if (mounted) setState(() => status = 'Backend not connected – start the Python server'); }
  }
  @override
  Widget build(BuildContext context) => PageFrame(title: 'Good day, Pharmacist', subtitle: 'Your integrated pharmacy practice workspace', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF087E8B), Color(0xFF155E75)]), borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Safer medication practice, supported by technology.', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8), const Text('A student-built educational prototype for pharmacy workflows.', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 16), Row(children: [const Icon(Icons.circle, size: 10, color: Colors.lightGreenAccent), const SizedBox(width: 8), Expanded(child: Text(status, style: const TextStyle(color: Colors.white)))])
      ])),
    const SizedBox(height: 22),
    Text('Pharmacy modules', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
    const SizedBox(height: 12),
    GridView.count(crossAxisCount: MediaQuery.of(context).size.width > 700 ? 3 : 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.25,
      children: const [
        ModuleTile(icon: Icons.document_scanner_outlined, title: 'Prescription Analyzer', desc: 'Extract and review text'),
        ModuleTile(icon: Icons.medication_outlined, title: 'Drug Information', desc: 'Search medicine records'),
        ModuleTile(icon: Icons.compare_arrows, title: 'Interaction Checker', desc: 'Screen selected medicines'),
        ModuleTile(icon: Icons.chat_bubble_outline, title: 'Patient Counselling', desc: 'English and Tamil'),
        ModuleTile(icon: Icons.health_and_safety_outlined, title: 'ADR Reporting', desc: 'Record suspected reactions'),
        ModuleTile(icon: Icons.alarm_outlined, title: 'Medication Adherence', desc: 'Schedules and dose logs'),
      ]),
    const SizedBox(height: 12),
    const Panel(child: Row(children: [Icon(Icons.shield_outlined, color: Color(0xFF087E8B)), SizedBox(width: 12), Expanded(child: Text('Educational prototype only. Verify all medicine information with authoritative references and a qualified pharmacist.'))])),
  ]));
}

class ModuleTile extends StatelessWidget {
  final IconData icon; final String title, desc;
  const ModuleTile({super.key, required this.icon, required this.title, required this.desc});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0xFFE7EEF0))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: const Color(0xFF087E8B), size: 27), const SizedBox(height: 10),
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 4),
      Text(desc, style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600)),
    ]),
  );
}

class PrescriptionPage extends StatefulWidget { const PrescriptionPage({super.key}); @override State<PrescriptionPage> createState()=>_PrescriptionPageState(); }
class _PrescriptionPageState extends State<PrescriptionPage> {
  final text = TextEditingController(); String result = ''; bool loading = false;
  Future<void> analyze() async {
    setState(()=>loading=true);
    try { final r=await ApiService.post('/prescriptions/analyze-text', {'text':text.text}); setState(()=>result=jsonEncode(r)); }
    catch(e){showError(context,e);} finally{setState(()=>loading=false);}
  }
  Future<void> pickImage() async {
    try {
      final image=await ImagePicker().pickImage(source: ImageSource.gallery);
      if(image==null)return;
      final req=http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}/prescriptions/ocr'));
      req.files.add(http.MultipartFile.fromBytes('file', await image.readAsBytes(), filename: image.name));
      final streamed=await req.send(); final body=await streamed.stream.bytesToString();
      final data=jsonDecode(body);
      if(data['available']==true){text.text=data['text']??''; setState(()=>result='OCR completed. Review the extracted text and press Analyze.');}
      else {setState(()=>result=data['message']??'OCR unavailable. Please enter text manually.');}
    } catch(e){showError(context,e);}
  }
  @override Widget build(BuildContext context)=>PageFrame(title:'Prescription Analyzer',subtitle:'Extract text and prepare it for pharmacist verification',child:Column(children:[
    Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('Prescription input',style:TextStyle(fontWeight:FontWeight.bold,fontSize:17)),
      const SizedBox(height:12), field(text,'Paste or enter prescription text',lines:7,hint:'Example: Type only fictional sample text.'),
      const SizedBox(height:12), OutlinedButton.icon(onPressed:pickImage,icon:const Icon(Icons.image_outlined),label:const Text('Choose prescription image (optional OCR)')),
      const SizedBox(height:10), actionButton(context,loading?'Analyzing…':'Analyze text',analyze,icon:Icons.document_scanner_outlined),
    ])),
    if(result.isNotEmpty) ...[const SizedBox(height:14),Panel(child:SelectableText(result))],
    const SizedBox(height:14),const SafetyNote(),
  ]));
}

class DrugInfoPage extends StatefulWidget { const DrugInfoPage({super.key}); @override State<DrugInfoPage> createState()=>_DrugInfoPageState(); }
class _DrugInfoPageState extends State<DrugInfoPage>{
  final q=TextEditingController(); List items=[]; bool loading=false;
  Future<void> search() async {setState(()=>loading=true);try{final r=await ApiService.get('/medicines?q=${Uri.encodeComponent(q.text)}');setState(()=>items=r);}catch(e){showError(context,e);}finally{setState(()=>loading=false);}}
  @override void initState(){super.initState();search();}
  @override Widget build(BuildContext context)=>PageFrame(title:'Drug Information',subtitle:'Search the local educational medicine database',child:Column(children:[
    Panel(child:Column(children:[field(q,'Search generic name or class'),const SizedBox(height:10),actionButton(context,'Search medicines',search,icon:Icons.search)])),
    const SizedBox(height:14),if(loading)const CircularProgressIndicator(),
    ...items.map((m)=>Padding(padding:const EdgeInsets.only(bottom:10),child:Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(m['generic_name']??'',style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
      Text('${m['drug_class']??''} • ${m['brand_examples']??''}',style:TextStyle(color:Colors.blueGrey.shade600)),
      const Divider(),_kv('Uses',m['uses']),_kv('Common side effects',m['common_side_effects']),_kv('Precautions',m['precautions']),_kv('Storage',m['storage']),
    ])))),
    const SafetyNote(),
  ]));
}

Widget _kv(String k,dynamic v)=>Padding(padding:const EdgeInsets.symmetric(vertical:3),child:Text('$k: ${v??''}'));

class InteractionPage extends StatefulWidget { const InteractionPage({super.key}); @override State<InteractionPage> createState()=>_InteractionPageState(); }
class _InteractionPageState extends State<InteractionPage>{
  final meds=TextEditingController(); String result='';
  Future<void> check()async{try{final names=meds.text.split(',').map((e)=>e.trim()).where((e)=>e.isNotEmpty).toList();final r=await ApiService.post('/interactions/check',{'medicines':names});setState(()=>result=jsonEncode(r));}catch(e){showError(context,e);}}
  @override Widget build(BuildContext context)=>PageFrame(title:'Drug Interaction Checker',subtitle:'Initial screening using a small curated demo dataset',child:Column(children:[
    Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      field(meds,'Medicine names separated by commas',lines:2,hint:'Example: Warfarin, Ibuprofen'),
      const SizedBox(height:12),actionButton(context,'Check interactions',check,icon:Icons.compare_arrows),
    ])),
    if(result.isNotEmpty)...[const SizedBox(height:14),Panel(child:SelectableText(result))],
    const SizedBox(height:12),const SafetyNote(),
  ]));
}

class CounsellingPage extends StatefulWidget { const CounsellingPage({super.key}); @override State<CounsellingPage> createState()=>_CounsellingPageState(); }
class _CounsellingPageState extends State<CounsellingPage>{
  final med=TextEditingController(), instructions=TextEditingController(); String language='English', result='';
  Future<void> generate()async{try{final r=await ApiService.post('/counselling',{'medicine':med.text,'instructions':instructions.text,'language':language});setState(()=>result=r['counselling']??'');}catch(e){showError(context,e);}}
  @override Widget build(BuildContext context)=>PageFrame(title:'Patient Counselling',subtitle:'Generate a basic educational counselling draft in English or Tamil',child:Column(children:[
    Panel(child:Column(children:[
      field(med,'Generic medicine name',hint:'Example: Paracetamol'),
      const SizedBox(height:10),field(instructions,'Prescription instructions (optional)',lines:2),
      const SizedBox(height:10),DropdownButtonFormField<String>(value:language,decoration:const InputDecoration(labelText:'Language'),items:const [DropdownMenuItem(value:'English',child:Text('English')),DropdownMenuItem(value:'Tamil',child:Text('தமிழ் / Tamil'))],onChanged:(v)=>setState(()=>language=v??'English')),
      const SizedBox(height:12),actionButton(context,'Generate counselling draft',generate,icon:Icons.chat),
    ])),
    if(result.isNotEmpty)...[const SizedBox(height:14),Panel(child:SelectableText(result,style:const TextStyle(height:1.5)))],
    const SizedBox(height:12),const SafetyNote(),
  ]));
}

class AdrPage extends StatefulWidget { const AdrPage({super.key}); @override State<AdrPage> createState()=>_AdrPageState(); }
class _AdrPageState extends State<AdrPage>{
  final code=TextEditingController(),med=TextEditingController(),reaction=TextEditingController(),onset=TextEditingController(),notes=TextEditingController();
  String seriousness='Not assessed', message='';
  Future<void> save()async{try{final r=await ApiService.post('/adrs',{'patient_code':code.text,'medicine':med.text,'reaction':reaction.text,'onset_date':onset.text,'seriousness':seriousness,'reporter_notes':notes.text});setState(()=>message=r['message']);}catch(e){showError(context,e);}}
  @override Widget build(BuildContext context)=>PageFrame(title:'Pharmacovigilance / ADR',subtitle:'Record suspected adverse drug reactions for professional review',child:Column(children:[
    Panel(child:Column(children:[
      field(code,'Fictional patient code (no name or phone)'),const SizedBox(height:9),
      field(med,'Suspected medicine'),const SizedBox(height:9),
      field(reaction,'Describe suspected reaction',lines:3),const SizedBox(height:9),
      field(onset,'Onset date (YYYY-MM-DD)'),const SizedBox(height:9),
      DropdownButtonFormField<String>(value:seriousness,decoration:const InputDecoration(labelText:'Seriousness assessment'),items:const ['Not assessed','Non-serious','Serious – requires urgent assessment'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>seriousness=v??'Not assessed')),
      const SizedBox(height:9),field(notes,'Reporter notes (optional)',lines:2),const SizedBox(height:12),
      actionButton(context,'Save suspected ADR',save,icon:Icons.save),
      if(message.isNotEmpty)Padding(padding:const EdgeInsets.only(top:10),child:Text(message,style:const TextStyle(color:Colors.green))),
    ])),const SizedBox(height:12),const SafetyNote(),
  ]));
}

class AdherencePage extends StatefulWidget { const AdherencePage({super.key}); @override State<AdherencePage> createState()=>_AdherencePageState(); }
class _AdherencePageState extends State<AdherencePage>{
  final code=TextEditingController(),med=TextEditingController(),instructions=TextEditingController(),time=TextEditingController();
  List schedules=[]; String message='';
  Future<void> load()async{try{final r=await ApiService.get('/adherence');setState(()=>schedules=r);}catch(e){showError(context,e);}}
  Future<void> save()async{try{final r=await ApiService.post('/adherence',{'patient_code':code.text,'medicine':med.text,'instructions':instructions.text,'reminder_time':time.text});setState(()=>message=r['message']);await load();}catch(e){showError(context,e);}}
  Future<void> log(dynamic id,String status)async{try{await ApiService.post('/adherence/$id/log',{'dose_date':DateTime.now().toIso8601String().substring(0,10),'status':status});setState(()=>message='Dose log saved');}catch(e){showError(context,e);}}
  @override void initState(){super.initState();load();}
  @override Widget build(BuildContext context)=>PageFrame(title:'Medication Adherence',subtitle:'Create schedules and record dose status (prototype tracker)',child:Column(children:[
    Panel(child:Column(children:[
      field(code,'Fictional patient code'),const SizedBox(height:9),field(med,'Medicine name'),const SizedBox(height:9),
      field(instructions,'Prescribed instructions (enter exactly as prescribed)'),const SizedBox(height:9),field(time,'Reminder time (e.g. 08:00)'),const SizedBox(height:12),
      actionButton(context,'Save schedule',save,icon:Icons.add_alarm),
      if(message.isNotEmpty)Text(message),
    ])),
    const SizedBox(height:15),Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('Saved schedules',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),TextButton(onPressed:load,child:const Text('Refresh'))]),
    ...schedules.map((s)=>Padding(padding:const EdgeInsets.only(bottom:9),child:Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(s['medicine']??'',style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17)),Text('${s['instructions']} • ${s['reminder_time']}'),
      const SizedBox(height:9),Wrap(spacing:8,children:[
        OutlinedButton(onPressed:()=>log(s['id'],'Taken'),child:const Text('Taken')),
        OutlinedButton(onPressed:()=>log(s['id'],'Missed'),child:const Text('Missed')),
        OutlinedButton(onPressed:()=>log(s['id'],'Skipped'),child:const Text('Skipped')),
      ])
    ])))),
    const SafetyNote(),
  ]));
}

class AssistantPage extends StatefulWidget { const AssistantPage({super.key}); @override State<AssistantPage> createState()=>_AssistantPageState(); }
class _AssistantPageState extends State<AssistantPage>{
  final q=TextEditingController();String language='English',answer='';bool loading=false;
  Future<void> ask()async{setState(()=>loading=true);try{final r=await ApiService.post('/assistant',{'question':q.text,'language':language});setState(()=>answer=r['answer']??'');}catch(e){showError(context,e);}finally{setState(()=>loading=false);}}
  @override Widget build(BuildContext context)=>PageFrame(title:'PharmaAI Assistant',subtitle:'Educational pharmacy information assistant',child:Column(children:[
    Panel(child:Column(children:[
      DropdownButtonFormField<String>(value:language,decoration:const InputDecoration(labelText:'Language'),items:const [DropdownMenuItem(value:'English',child:Text('English')),DropdownMenuItem(value:'Tamil',child:Text('Tamil'))],onChanged:(v)=>setState(()=>language=v??'English')),
      const SizedBox(height:10),field(q,'Ask a general pharmacy question',lines:3),const SizedBox(height:12),
      actionButton(context,loading?'Please wait…':'Ask PharmaAI',ask,icon:Icons.send),
    ])),
    if(answer.isNotEmpty)...[const SizedBox(height:14),Panel(child:SelectableText(answer,style:const TextStyle(height:1.5)))],
    const SizedBox(height:12),const SafetyNote(),
  ]));
}

class SafetyNote extends StatelessWidget {
  const SafetyNote({super.key});
  @override Widget build(BuildContext context)=>Container(
    padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:const Color(0xFFFFF5E6),borderRadius:BorderRadius.circular(14)),
    child:const Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Icon(Icons.warning_amber_rounded,color:Color(0xFF9A5B00)),SizedBox(width:9),
      Expanded(child:Text('Educational prototype only. The sample database is incomplete. Verify all details with current authoritative references and a qualified pharmacist. Never use this app to diagnose, prescribe or change treatment.')),
    ]),
  );
}
