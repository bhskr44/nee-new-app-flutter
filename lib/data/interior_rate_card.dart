// Central rate card for interior/finishing work, sourced from the client's
// handwritten rate sheet (Jul 2026). Single source of truth — used by both
// the per-category tools in calculator_screen.dart and the combined
// Full Interior Cost Calculator wizard in house_calculator_screen.dart.
// Keep both in sync by editing these values only, never per-screen copies.

const double tileWithRate = 150.0;
const double tileWithoutRate = 25.0;

const double paintWithRate = 30.0;
const double paintWithoutRate = 12.0;

const double waterproofWithRate = 45.0;
const double waterproofWithoutRate = 25.0;

const Map<String, double> ceilingWithRates = {'Gypsum / Gyproc': 85.0, 'PVC': 120.0};
const Map<String, double> ceilingWithoutRates = {'Gypsum / Gyproc': 25.0, 'PVC': 25.0};

const Map<String, double> panelWithRates = {'PVC': 70.0, 'Chocolate Laminate': 130.0};
const Map<String, double> panelWithoutRates = {'PVC': 25.0, 'Chocolate Laminate': 20.0};

const Map<String, double> partitionWithRates = {'Glass & Rubber': 130.0, 'Wooden': 950.0};
// Glass & Rubber "without material" figure was smudged on the client's sheet —
// confirm with the client before relying on this number.
const Map<String, double> partitionWithoutRates = {'Glass & Rubber': 65.0, 'Wooden': 350.0};

const Map<String, double> wallpaperWithRates = {'Modern': 55.0, 'Premium': 80.0};
const double wallpaperWithoutRate = 600.0; // flat per roll, both types

const double electricalWithRate = 150.0;
const double electricalWithoutRate = 40.0;

const Map<String, double> plumbingWithRates = {'Normal': 35000.0, 'Premium': 55000.0, 'Duplex': 90000.0};
const Map<String, double> plumbingWithoutRates = {'Normal': 15000.0, 'Premium': 30000.0, 'Duplex': 40000.0};

const Map<String, double> kitchenWithRates = {'Medium': 1799.0, 'Premium': 2250.0, 'Duplex': 2900.0};
const Map<String, double> kitchenWithoutRates = {'Medium': 350.0, 'Premium': 450.0, 'Duplex': 550.0};

const Map<String, double> wardrobeWithRates = {'Openable': 1450.0, 'Sliding': 1990.0};
const Map<String, double> wardrobeWithoutRates = {'Openable': 350.0, 'Sliding': 400.0};

const Map<String, double> bedWithRates = {'Medium': 45000.0, 'Premium': 56000.0, 'Duplex': 85000.0};
const Map<String, double> bedWithoutRates = {'Medium': 400.0, 'Premium': 420.0, 'Duplex': 450.0};

const double homeAutomationRate = 45000.0; // per room

const Map<String, double> msRailingWithRates = {'Medium': 750.0, 'Premium': 850.0, 'Duplex': 2400.0}; // per RFT
const Map<String, double> msRailingWithoutRates = {'Medium': 150.0, 'Premium': 210.0, 'Duplex': 250.0}; // per RFT

const Map<String, double> tvUnitWithRates = {'Medium': 1450.0, 'Premium': 1600.0, 'Duplex': 1799.0}; // per sqft
const Map<String, double> tvUnitWithoutRates = {'Medium': 290.0, 'Premium': 320.0, 'Duplex': 370.0}; // per sqft

const Map<String, double> basinCabinetWithRates = {'Medium': 1200.0, 'Premium': 1350.0, 'Duplex': 1650.0}; // per sqft
const Map<String, double> basinCabinetWithoutRates = {'Medium': 250.0, 'Premium': 350.0, 'Duplex': 400.0}; // per sqft
