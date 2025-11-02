  Future<void> _processImage() async {
    try {
      final XFile? selectedImage = await BillImagePicker.pickImage(context);
      
      if (selectedImage == null) {
        if (mounted) {
          Helpers.showSnackBar(
            context,
            'No image selected',
            isError: true,
          );
        }
        return;
      }

      // Show bill type selection dialog
      final billType = await _showBillTypeDialog();
      
      if (billType != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScanScreen(
              imageFile: selectedImage,
              billType: billType,
            ),
          ),
        ).then((_) {
          _loadRecentReports();
          _loadMonthlyStats();
        });
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error picking image: $e',
          isError: true,
        );
      }
    }
  }