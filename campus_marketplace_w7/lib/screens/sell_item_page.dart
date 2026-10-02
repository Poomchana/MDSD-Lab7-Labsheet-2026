import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/listing_draft.dart';
import '../services/gemini_vision_service.dart';

class SellItemPage extends StatefulWidget {
  const SellItemPage({super.key});

  @override
  State<SellItemPage> createState() => _SellItemPageState();
}

class _SellItemPageState extends State<SellItemPage> {
  File? _selectedImage;
  bool _isLoading = false;

  // Controller สำหรับรับค่าไปใส่ในช่องกรอกข้อมูลและแก้ไขก่อนยืนยัน
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _geminiService = GeminiVisionService();

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
    });
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกรูปภาพก่อนให้ AI วิเคราะห์')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final draft = await _geminiService.analyzeProductImage(_selectedImage!);
      setState(() {
        _titleController.text = draft.title;
        _categoryController.text = draft.category;
        _descriptionController.text = draft.description;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('วิเคราะห์ข้อมูลสินค้าสำเร็จ!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ฟังก์ชันสำหรับยืนยันร่างประกาศและล้างฟอร์ม (ขั้นตอนที่ 5.2)
  void _submitDraft() {
    // เช็กว่ามีการเลือกรูปภาพและกรอกข้อมูลเบื้องต้นหรือไม่
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกรูปภาพสินค้าก่อนยืนยัน')),
      );
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณากรอกชื่อสินค้า')));
      return;
    }

    // สร้างอ็อบเจกต์ร่างประกาศฉบับสุดท้ายที่ผ่านการแก้ไขแล้ว
    final finalDraft = ListingDraft(
      title: _titleController.text,
      category: _categoryController.text,
      description: _descriptionController.text,
    );

    // แสดง SnackBar ยืนยันการบันทึก
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('บันทึกร่างประกาศ "${finalDraft.title}" เรียบร้อยแล้ว'),
        backgroundColor: Colors.green,
      ),
    );

    // ล้างค่าในฟอร์มทั้งหมดกลับสู่สถานะว่างเปล่า
    setState(() {
      _selectedImage = null;
      _titleController.clear();
      _categoryController.clear();
      _descriptionController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ลงขายสินค้า')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // แสดงรูปภาพตัวอย่าง
            if (_selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.file(
                  _selectedImage!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'ยังไม่ได้เลือกรูปภาพ',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // ปุ่มเลือกรูปภาพ
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('เลือกรูปภาพสินค้า'),
            ),
            const SizedBox(height: 12),

            // ปุ่มให้ AI ช่วยแนะนำ
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _analyzeImage,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('ให้ AI ช่วยแนะนำ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[100],
                foregroundColor: Colors.purple[900],
              ),
            ),
            const SizedBox(height: 20),

            // แสดงสถานะกำลังโหลด
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('AI กำลังวิเคราะห์ภาพสินค้า...'),
                  ],
                ),
              ),

            // ช่องกรอกข้อมูลสำหรับตรวจทานและแก้ไข (TextFields)
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'ชื่อสินค้า',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'หมวดหมู่',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'รายละเอียดสินค้า',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // ปุ่มยืนยันร่างประกาศ (ขั้นตอนที่ 5.2)
            ElevatedButton(
              onPressed: _isLoading ? null : _submitDraft,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'ยืนยันร่างประกาศ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
