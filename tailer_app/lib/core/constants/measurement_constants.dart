/// Measurement constants for the tailor app
/// Contains dress types and their corresponding measurement categories
library;

class MeasurementConstants {
  // Dress Types
  static const Map<String, Map<String, dynamic>> dressTypes = {
    'shirt': {
      'name': 'Shirt',
      'icon': 'shirt',
      'description': 'Formal and casual shirts',
      'measurements': [
        'chest',
        'shoulder',
        'sleeve_length',
        'shirt_length',
        'neck',
        'waist',
        'hip',
      ],
    },
    'pant': {
      'name': 'Pant',
      'icon': 'pant',
      'description': 'Formal and casual pants',
      'measurements': [
        'waist',
        'hip',
        'thigh',
        'knee',
        'calf',
        'ankle',
        'pant_length',
        'inseam',
        'rise',
      ],
    },
    'suit': {
      'name': 'Suit',
      'icon': 'suit',
      'description': 'Full suit (jacket + pant)',
      'measurements': [
        'chest',
        'shoulder',
        'sleeve_length',
        'jacket_length',
        'neck',
        'waist',
        'hip',
        'thigh',
        'knee',
        'pant_length',
        'inseam',
        'rise',
      ],
    },
    'blazer': {
      'name': 'Blazer',
      'icon': 'blazer',
      'description': 'Business blazer or jacket',
      'measurements': [
        'chest',
        'shoulder',
        'sleeve_length',
        'jacket_length',
        'neck',
        'waist',
        'hip',
      ],
    },
    'kurta': {
      'name': 'Kurta',
      'icon': 'kurta',
      'description': 'Traditional Indian kurta',
      'measurements': [
        'chest',
        'shoulder',
        'sleeve_length',
        'kurta_length',
        'neck',
        'waist',
        'hip',
      ],
    },
    'sherwani': {
      'name': 'Sherwani',
      'icon': 'sherwani',
      'description': 'Traditional formal wear',
      'measurements': [
        'chest',
        'shoulder',
        'sleeve_length',
        'sherwani_length',
        'neck',
        'waist',
        'hip',
        'collar',
      ],
    },
    'dress': {
      'name': 'Dress',
      'icon': 'dress',
      'description': 'Women\'s dress',
      'measurements': [
        'bust',
        'waist',
        'hip',
        'shoulder',
        'sleeve_length',
        'dress_length',
        'neck',
      ],
    },
    'blouse': {
      'name': 'Blouse',
      'icon': 'blouse',
      'description': 'Traditional blouse',
      'measurements': [
        'bust',
        'waist',
        'shoulder',
        'sleeve_length',
        'blouse_length',
        'neck',
        'armhole',
      ],
    },
    'lehenga': {
      'name': 'Lehenga',
      'icon': 'lehenga',
      'description': 'Traditional lehenga set',
      'measurements': [
        'bust',
        'waist',
        'hip',
        'shoulder',
        'sleeve_length',
        'choli_length',
        'lehenga_length',
        'lehenga_waist',
      ],
    },
    'saree_blouse': {
      'name': 'Saree Blouse',
      'icon': 'saree_blouse',
      'description': 'Blouse for saree',
      'measurements': [
        'bust',
        'waist',
        'shoulder',
        'sleeve_length',
        'blouse_length',
        'neck',
        'armhole',
        'back_neck',
      ],
    },
  };

  // Measurement Categories with descriptions and units
  static const Map<String, Map<String, dynamic>> measurementCategories = {
    // Upper Body Measurements
    'chest': {
      'name': 'Chest',
      'description': 'Around the fullest part of the chest',
      'unit': 'inches',
      'category': 'Upper Body',
      'instruction': 'Measure around the fullest part of the chest, keeping the tape parallel to the ground',
      'gender': 'male',
    },
    'bust': {
      'name': 'Bust',
      'description': 'Around the fullest part of the bust',
      'unit': 'inches',
      'category': 'Upper Body',
      'instruction': 'Measure around the fullest part of the bust, keeping the tape parallel to the ground',
      'gender': 'female',
    },
    'shoulder': {
      'name': 'Shoulder',
      'description': 'Shoulder to shoulder measurement',
      'unit': 'inches',
      'category': 'Upper Body',
      'instruction': 'Measure from shoulder point to shoulder point across the back',
      'gender': 'both',
    },
    'sleeve_length': {
      'name': 'Sleeve Length',
      'description': 'Shoulder to wrist measurement',
      'unit': 'inches',
      'category': 'Upper Body',
      'instruction': 'Measure from shoulder point to wrist with arm slightly bent',
      'gender': 'both',
    },
    'neck': {
      'name': 'Neck',
      'description': 'Around the neck circumference',
      'unit': 'inches',
      'category': 'Upper Body',
      'instruction': 'Measure around the base of the neck where the collar would sit',
      'gender': 'both',
    },
    'back_neck': {
      'name': 'Back Neck',
      'description': 'Back neck depth',
      'unit': 'inches',
      'category': 'Upper Body',
      'instruction': 'Measure the depth of back neck opening',
      'gender': 'female',
    },
    'armhole': {
      'name': 'Armhole',
      'description': 'Around the armhole circumference',
      'unit': 'inches',
      'category': 'Upper Body',
      'instruction': 'Measure around the armhole opening',
      'gender': 'both',
    },
    'collar': {
      'name': 'Collar',
      'description': 'Collar size measurement',
      'unit': 'inches',
      'category': 'Upper Body',
      'instruction': 'Measure around the neck for collar fitting',
      'gender': 'male',
    },

    // Torso Measurements
    'waist': {
      'name': 'Waist',
      'description': 'Around the natural waistline',
      'unit': 'inches',
      'category': 'Torso',
      'instruction': 'Measure around the narrowest part of the waist',
      'gender': 'both',
    },
    'hip': {
      'name': 'Hip',
      'description': 'Around the fullest part of the hips',
      'unit': 'inches',
      'category': 'Torso',
      'instruction': 'Measure around the fullest part of the hips',
      'gender': 'both',
    },

    // Lower Body Measurements
    'thigh': {
      'name': 'Thigh',
      'description': 'Around the fullest part of the thigh',
      'unit': 'inches',
      'category': 'Lower Body',
      'instruction': 'Measure around the fullest part of the thigh',
      'gender': 'both',
    },
    'knee': {
      'name': 'Knee',
      'description': 'Around the knee circumference',
      'unit': 'inches',
      'category': 'Lower Body',
      'instruction': 'Measure around the knee with leg slightly bent',
      'gender': 'both',
    },
    'calf': {
      'name': 'Calf',
      'description': 'Around the fullest part of the calf',
      'unit': 'inches',
      'category': 'Lower Body',
      'instruction': 'Measure around the fullest part of the calf',
      'gender': 'both',
    },
    'ankle': {
      'name': 'Ankle',
      'description': 'Around the ankle circumference',
      'unit': 'inches',
      'category': 'Lower Body',
      'instruction': 'Measure around the ankle above the ankle bone',
      'gender': 'both',
    },
    'inseam': {
      'name': 'Inseam',
      'description': 'Inner leg measurement',
      'unit': 'inches',
      'category': 'Lower Body',
      'instruction': 'Measure from the crotch to the ankle along the inner leg',
      'gender': 'both',
    },
    'rise': {
      'name': 'Rise',
      'description': 'Waist to crotch measurement',
      'unit': 'inches',
      'category': 'Lower Body',
      'instruction': 'Measure from the waist to the crotch point',
      'gender': 'both',
    },

    // Length Measurements
    'shirt_length': {
      'name': 'Shirt Length',
      'description': 'Shoulder to bottom hem',
      'unit': 'inches',
      'category': 'Length',
      'instruction': 'Measure from the shoulder point to the desired shirt length',
      'gender': 'both',
    },
    'jacket_length': {
      'name': 'Jacket Length',
      'description': 'Shoulder to bottom hem of jacket',
      'unit': 'inches',
      'category': 'Length',
      'instruction': 'Measure from the shoulder point to the desired jacket length',
      'gender': 'both',
    },
    'kurta_length': {
      'name': 'Kurta Length',
      'description': 'Shoulder to bottom hem of kurta',
      'unit': 'inches',
      'category': 'Length',
      'instruction': 'Measure from the shoulder point to the desired kurta length',
      'gender': 'both',
    },
    'sherwani_length': {
      'name': 'Sherwani Length',
      'description': 'Shoulder to bottom hem of sherwani',
      'unit': 'inches',
      'category': 'Length',
      'instruction': 'Measure from the shoulder point to the desired sherwani length',
      'gender': 'male',
    },
    'pant_length': {
      'name': 'Pant Length',
      'description': 'Waist to ankle measurement',
      'unit': 'inches',
      'category': 'Length',
      'instruction': 'Measure from the waist to the ankle or desired pant length',
      'gender': 'both',
    },
    'dress_length': {
      'name': 'Dress Length',
      'description': 'Shoulder to hem of dress',
      'unit': 'inches',
      'category': 'Length',
      'instruction': 'Measure from the shoulder point to the desired dress length',
      'gender': 'female',
    },
    'blouse_length': {
      'name': 'Blouse Length',
      'description': 'Shoulder to bottom hem of blouse',
      'unit': 'inches',
      'category': 'Length',
      'instruction': 'Measure from the shoulder point to the desired blouse length',
      'gender': 'female',
    },
    'choli_length': {
      'name': 'Choli Length',
      'description': 'Shoulder to bottom hem of choli',
      'unit': 'inches',
      'category': 'Length',
      'instruction': 'Measure from the shoulder point to the desired choli length',
      'gender': 'female',
    },
    'lehenga_length': {
      'name': 'Lehenga Length',
      'description': 'Waist to floor for lehenga skirt',
      'unit': 'inches',
      'category': 'Length',
      'instruction': 'Measure from the waist to the floor for lehenga skirt length',
      'gender': 'female',
    },
    'lehenga_waist': {
      'name': 'Lehenga Waist',
      'description': 'Waist measurement for lehenga skirt',
      'unit': 'inches',
      'category': 'Torso',
      'instruction': 'Measure around the waist where the lehenga will sit',
      'gender': 'female',
    },
  };

  // Measurement categories grouped by type
  static const Map<String, List<String>> categoryGroups = {
    'Upper Body': [
      'chest',
      'bust',
      'shoulder',
      'sleeve_length',
      'neck',
      'back_neck',
      'armhole',
      'collar',
    ],
    'Torso': [
      'waist',
      'hip',
      'lehenga_waist',
    ],
    'Lower Body': [
      'thigh',
      'knee',
      'calf',
      'ankle',
      'inseam',
      'rise',
    ],
    'Length': [
      'shirt_length',
      'jacket_length',
      'kurta_length',
      'sherwani_length',
      'pant_length',
      'dress_length',
      'blouse_length',
      'choli_length',
      'lehenga_length',
    ],
  };

  // Get measurements for a specific dress type
  static List<String> getMeasurementsForDressType(String dressType) {
    return List<String>.from(dressTypes[dressType]?['measurements'] ?? []);
  }

  // Get measurement details
  static Map<String, dynamic>? getMeasurementDetails(String measurementKey) {
    return measurementCategories[measurementKey];
  }

  // Get dress type details
  static Map<String, dynamic>? getDressTypeDetails(String dressTypeKey) {
    return dressTypes[dressTypeKey];
  }

  // Get all dress types as a list
  static List<String> getAllDressTypes() {
    return dressTypes.keys.toList();
  }

  // Get all measurement categories as a list
  static List<String> getAllMeasurementCategories() {
    return measurementCategories.keys.toList();
  }

  // Filter measurements by gender
  static List<String> getMeasurementsByGender(String gender) {
    return measurementCategories.entries
        .where((entry) => 
            entry.value['gender'] == gender || 
            entry.value['gender'] == 'both')
        .map((entry) => entry.key)
        .toList();
  }

  // Get measurements by category group
  static List<String> getMeasurementsByCategory(String category) {
    return categoryGroups[category] ?? [];
  }
}