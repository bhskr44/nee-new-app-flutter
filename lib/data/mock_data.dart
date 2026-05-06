import 'package:flutter/material.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class Product {
  final String id, name, category, supplier, unit, location, description;
  final double price, rating;
  final int reviews;
  final Color color;
  final IconData icon;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.supplier,
    required this.unit,
    required this.location,
    required this.description,
    required this.price,
    required this.rating,
    required this.reviews,
    required this.color,
    required this.icon,
  });
}

class Worker {
  final String id, name, trade, location, phone, experience;
  final double dailyRate, rating;
  final bool available;
  final List<String> skills;

  const Worker({
    required this.id,
    required this.name,
    required this.trade,
    required this.location,
    required this.phone,
    required this.experience,
    required this.dailyRate,
    required this.rating,
    required this.available,
    required this.skills,
  });
}

class Lead {
  final String id, title, projectType, location, description, contact, postedDate, status;
  final double value;
  final bool isBuy;

  const Lead({
    required this.id,
    required this.title,
    required this.projectType,
    required this.location,
    required this.description,
    required this.contact,
    required this.postedDate,
    required this.status,
    required this.value,
    required this.isBuy,
  });
}

class FundingOption {
  final String id, name, provider, type, description, eligibility, duration;
  final double minAmount, maxAmount, interestRate;

  const FundingOption({
    required this.id,
    required this.name,
    required this.provider,
    required this.type,
    required this.description,
    required this.eligibility,
    required this.duration,
    required this.minAmount,
    required this.maxAmount,
    required this.interestRate,
  });
}

class BusinessType {
  final String id, name, description, minInvestment, maxInvestment, returns;
  final List<String> steps, documents;
  final IconData icon;
  final Color color;

  const BusinessType({
    required this.id,
    required this.name,
    required this.description,
    required this.minInvestment,
    required this.maxInvestment,
    required this.returns,
    required this.steps,
    required this.documents,
    required this.icon,
    required this.color,
  });
}

class Job {
  final String id, title, company, location, jobType, minSalary, maxSalary, deadline, description;
  final List<String> requirements;

  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.jobType,
    required this.minSalary,
    required this.maxSalary,
    required this.deadline,
    required this.description,
    required this.requirements,
  });
}

class TrainingCourse {
  final String id, name, provider, duration, certification, description, mode;
  final double fee;

  const TrainingCourse({
    required this.id,
    required this.name,
    required this.provider,
    required this.duration,
    required this.certification,
    required this.description,
    required this.mode,
    required this.fee,
  });
}

class AreaContact {
  final String district;
  final String region;
  final String name;
  final String designation;
  final String phone;

  const AreaContact({
    required this.district,
    required this.region,
    required this.name,
    required this.designation,
    required this.phone,
  });
}

// ─── Products ────────────────────────────────────────────────────────────────

final List<Product> mockProducts = [
  const Product(
    id: 'p1', name: 'UltraTech Cement 43 Grade', category: 'Cement',
    supplier: 'Ramesh Trading Co.', unit: 'per bag (50kg)', location: 'Bengaluru',
    description: 'Premium PPC cement ideal for all general construction purposes. High strength & durability.',
    price: 380, rating: 4.5, reviews: 1248, color: Color(0xFF5D4037), icon: Icons.water_drop,
  ),
  const Product(
    id: 'p2', name: 'ACC Gold OPC 53 Grade', category: 'Cement',
    supplier: 'Sri Distributors', unit: 'per bag (50kg)', location: 'Chennai',
    description: 'High early strength cement for RCC and prestressed concrete works.',
    price: 395, rating: 4.3, reviews: 876, color: Color(0xFF795548), icon: Icons.water_drop,
  ),
  const Product(
    id: 'p3', name: 'Coromandel Cement OPC', category: 'Cement',
    supplier: 'Anand Agencies', unit: 'per bag (50kg)', location: 'Hyderabad',
    description: 'Best suited for RCC, foundations and structural elements.',
    price: 368, rating: 4.4, reviews: 642, color: Color(0xFF6D4C41), icon: Icons.water_drop,
  ),
  const Product(
    id: 'p4', name: 'Tata Tiscon Fe 500D TMT 12mm', category: 'Steel',
    supplier: 'Tata Steel Ltd.', unit: 'per MT', location: 'Mumbai',
    description: 'Earthquake-resistant Fe 500D grade TMT bars. Superior bend & rebend properties.',
    price: 62500, rating: 4.8, reviews: 2341, color: Color(0xFF37474F), icon: Icons.straighten,
  ),
  const Product(
    id: 'p5', name: 'JSW Neosteel TMT Fe 500 16mm', category: 'Steel',
    supplier: 'JSW Steel Distributors', unit: 'per MT', location: 'Bengaluru',
    description: 'High strength corrosion-resistant TMT bars for heavy structural work.',
    price: 61800, rating: 4.7, reviews: 1879, color: Color(0xFF455A64), icon: Icons.straighten,
  ),
  const Product(
    id: 'p6', name: 'Fly Ash Bricks (6×4×3 inch)', category: 'Bricks',
    supplier: 'Lakshmi Brick Works', unit: 'per piece', location: 'Bengaluru',
    description: 'Eco-friendly, high compressive strength fly ash bricks. Thermal insulation properties.',
    price: 5.5, rating: 4.2, reviews: 523, color: Color(0xFFBF360C), icon: Icons.grid_on,
  ),
  const Product(
    id: 'p7', name: 'Red Clay Wire Cut Bricks', category: 'Bricks',
    supplier: 'Kumar Brick Industries', unit: 'per piece', location: 'Hyderabad',
    description: 'Premium red clay bricks. High durability and traditional aesthetics.',
    price: 8.0, rating: 4.0, reviews: 312, color: Color(0xFFD84315), icon: Icons.grid_on,
  ),
  const Product(
    id: 'p8', name: 'M-Sand (Manufactured Sand)', category: 'Sand',
    supplier: 'Solid Aggregates Pvt Ltd', unit: 'per brass', location: 'Bengaluru',
    description: 'Washed and graded manufactured sand. Better alternative to river sand.',
    price: 1250, rating: 4.4, reviews: 678, color: Color(0xFFF9A825), icon: Icons.terrain,
  ),
  const Product(
    id: 'p9', name: '20mm Blue Metal Aggregate', category: 'Aggregates',
    supplier: 'Rock Solid Quarry', unit: 'per brass', location: 'Coimbatore',
    description: 'Cubical shaped, clean granite aggregates for concrete work.',
    price: 980, rating: 4.3, reviews: 441, color: Color(0xFF616161), icon: Icons.grain,
  ),
  const Product(
    id: 'p10', name: 'Kajaria Vitro Floor Tiles 600×600mm', category: 'Tiles',
    supplier: 'Kajaria Authorised Dealer', unit: 'per sqft', location: 'Delhi',
    description: 'Premium double charged vitrified tiles. Anti-skid, high gloss finish.',
    price: 55, rating: 4.6, reviews: 1123, color: Color(0xFF1565C0), icon: Icons.crop_square,
  ),
  const Product(
    id: 'p11', name: 'Asian Paints Apex Ultima Exterior', category: 'Paint',
    supplier: 'Color World Dealers', unit: 'per litre', location: 'Mumbai',
    description: '7-year warranty exterior emulsion with UV protection & weather resistance.',
    price: 325, rating: 4.5, reviews: 2567, color: Color(0xFF1B5E20), icon: Icons.format_paint,
  ),
  const Product(
    id: 'p12', name: 'Berger Silk Luxury Emulsion Interior', category: 'Paint',
    supplier: 'Paints & More', unit: 'per litre', location: 'Kolkata',
    description: 'Smooth finish interior emulsion with anti-bacterial properties.',
    price: 285, rating: 4.4, reviews: 1834, color: Color(0xFF4A148C), icon: Icons.format_paint,
  ),
  const Product(
    id: 'p13', name: 'Supreme CPVC Pipes 1/2 inch', category: 'Pipes',
    supplier: 'Plumbing Wholesale Hub', unit: 'per metre', location: 'Ahmedabad',
    description: 'Hot & cold water CPVC pipes. Lead-free, chemical resistant.',
    price: 95, rating: 4.2, reviews: 387, color: Color(0xFFE65100), icon: Icons.water,
  ),
  const Product(
    id: 'p14', name: 'Havells 4 sq mm FR Wire (90m)', category: 'Electrical',
    supplier: 'Electric Bazaar', unit: 'per coil', location: 'Delhi',
    description: 'Fire-retardant insulated copper wires. ISI certified.',
    price: 1850, rating: 4.7, reviews: 2103, color: Color(0xFFF57F17), icon: Icons.electrical_services,
  ),
];

// ─── Workers ─────────────────────────────────────────────────────────────────

final List<Worker> mockWorkers = [
  const Worker(
    id: 'w1', name: 'Raja Muthu', trade: 'Mason', location: 'Bengaluru',
    phone: '+91 98765 43210', experience: '15 Years', dailyRate: 750,
    rating: 4.6, available: true, skills: ['Bricklaying', 'Plastering', 'RCC Slab', 'Block Work'],
  ),
  const Worker(
    id: 'w2', name: 'Kumar Pillai', trade: 'Plumber', location: 'Chennai',
    phone: '+91 97654 32109', experience: '10 Years', dailyRate: 850,
    rating: 4.4, available: true, skills: ['CPVC', 'PPR', 'Sanitary Fitting', 'Drainage'],
  ),
  const Worker(
    id: 'w3', name: 'Senthil Vel', trade: 'Electrician', location: 'Hyderabad',
    phone: '+91 96543 21098', experience: '12 Years', dailyRate: 900,
    rating: 4.7, available: false, skills: ['Wiring', 'Panel Work', 'MCB Fitting', 'AC Installation'],
  ),
  const Worker(
    id: 'w4', name: 'Raman Krishnan', trade: 'Carpenter', location: 'Mumbai',
    phone: '+91 95432 10987', experience: '8 Years', dailyRate: 800,
    rating: 4.3, available: true, skills: ['Door Frames', 'Formwork', 'Shuttering', 'Furniture'],
  ),
  const Worker(
    id: 'w5', name: 'Vinod Sharma', trade: 'Painter', location: 'Delhi',
    phone: '+91 94321 09876', experience: '6 Years', dailyRate: 650,
    rating: 4.1, available: true, skills: ['Emulsion', 'Enamel', 'Putty', 'Texture Coating'],
  ),
  const Worker(
    id: 'w6', name: 'Arjun Tiwari', trade: 'Tiler', location: 'Pune',
    phone: '+91 93210 98765', experience: '5 Years', dailyRate: 700,
    rating: 4.5, available: true, skills: ['Floor Tiling', 'Wall Cladding', 'Grouting', 'Waterproofing'],
  ),
  const Worker(
    id: 'w7', name: 'Mani Sundaram', trade: 'Welder', location: 'Coimbatore',
    phone: '+91 92109 87654', experience: '9 Years', dailyRate: 950,
    rating: 4.6, available: false, skills: ['Arc Welding', 'MIG Welding', 'Gate Fabrication', 'Railing'],
  ),
  const Worker(
    id: 'w8', name: 'Suresh Reddy', trade: 'Site Supervisor', location: 'Bengaluru',
    phone: '+91 91098 76543', experience: '20 Years', dailyRate: 1600,
    rating: 4.8, available: true, skills: ['Labour Management', 'Quality Control', 'Safety', 'Scheduling'],
  ),
  const Worker(
    id: 'w9', name: 'Deepak Nair', trade: 'False Ceiling Worker', location: 'Mumbai',
    phone: '+91 90987 65432', experience: '4 Years', dailyRate: 720,
    rating: 4.2, available: true, skills: ['Grid Ceiling', 'Gypsum Board', 'POP Cornice', 'LED Strip Work'],
  ),
  const Worker(
    id: 'w10', name: 'Ganesh Murugan', trade: 'Plumber', location: 'Bengaluru',
    phone: '+91 89876 54321', experience: '7 Years', dailyRate: 800,
    rating: 4.3, available: true, skills: ['Water Proofing', 'Sump Work', 'STP', 'Bore Well Fitting'],
  ),
];

// ─── Leads ───────────────────────────────────────────────────────────────────

final List<Lead> mockLeads = [
  const Lead(
    id: 'l1', title: '2BHK Residential Construction', projectType: 'New Construction',
    location: 'Whitefield, Bengaluru', value: 4500000, isBuy: true,
    description: 'Ground floor 2BHK duplex home construction on 1200 sqft plot. Civil + Electrical + Plumbing.',
    contact: '+91 98765 11111', postedDate: '2 days ago', status: 'Active',
  ),
  const Lead(
    id: 'l2', title: 'Villa Renovation & Interiors', projectType: 'Renovation',
    location: 'ECR Road, Chennai', value: 1200000, isBuy: true,
    description: 'Complete renovation of 3BHK villa — false ceiling, flooring, paint, bathroom fittings.',
    contact: '+91 87654 22222', postedDate: '5 days ago', status: 'Active',
  ),
  const Lead(
    id: 'l3', title: 'G+3 Commercial Building', projectType: 'Commercial',
    location: 'Banjara Hills, Hyderabad', value: 18000000, isBuy: true,
    description: '4-storey commercial complex on 3000 sqft plot. Complete civil structural work needed.',
    contact: '+91 76543 33333', postedDate: '1 week ago', status: 'Active',
  ),
  const Lead(
    id: 'l4', title: 'Industrial Warehouse Construction', projectType: 'Industrial',
    location: 'Chakan, Pune', value: 6500000, isBuy: true,
    description: '15,000 sqft pre-engineered building with mezzanine floor. Urgently needed.',
    contact: '+91 65432 44444', postedDate: '3 days ago', status: 'Active',
  ),
  const Lead(
    id: 'l5', title: 'School Building Block Addition', projectType: 'Institutional',
    location: 'Coimbatore', value: 9500000, isBuy: true,
    description: 'New classroom block (G+2) with 12 classrooms, washrooms, and corridors.',
    contact: '+91 54321 55555', postedDate: '10 days ago', status: 'Negotiating',
  ),
  const Lead(
    id: 'l6', title: 'Painting Contract — 5000 sqft Commercial', projectType: 'Painting',
    location: 'Andheri, Mumbai', value: 350000, isBuy: false,
    description: 'Completed painting work lead. 2-coat exterior texture + interior emulsion for IT office.',
    contact: '+91 43210 66666', postedDate: '1 day ago', status: 'Available',
  ),
  const Lead(
    id: 'l7', title: 'Plumbing Works — 20 Apartment Complex', projectType: 'Plumbing',
    location: 'Marathahalli, Bengaluru', value: 420000, isBuy: false,
    description: 'CPVC plumbing + drainage for 20-unit apartment. Materials included.',
    contact: '+91 32109 77777', postedDate: '4 days ago', status: 'Available',
  ),
  const Lead(
    id: 'l8', title: 'False Ceiling — Hospital OPD Block', projectType: 'False Ceiling',
    location: 'Anna Nagar, Chennai', value: 280000, isBuy: false,
    description: '8,000 sqft grid ceiling with gypsum board and mineral fiber tiles. Urgent.',
    contact: '+91 21098 88888', postedDate: '2 days ago', status: 'Available',
  ),
];

// ─── Funding Options ──────────────────────────────────────────────────────────

final List<FundingOption> mockFunding = [
  const FundingOption(
    id: 'f1', name: 'PM Mudra Yojana — Shishu', provider: 'Government of India',
    type: 'Government Scheme', description: 'Micro loans for small contractors and material suppliers just starting out.',
    eligibility: 'Any Indian citizen starting a business', duration: '1–5 years',
    minAmount: 10000, maxAmount: 50000, interestRate: 7.0,
  ),
  const FundingOption(
    id: 'f2', name: 'PM Mudra Yojana — Kishore', provider: 'Government of India',
    type: 'Government Scheme', description: 'Funds for established small businesses to expand operations.',
    eligibility: 'Existing micro enterprises with good repayment history', duration: '3–7 years',
    minAmount: 50000, maxAmount: 500000, interestRate: 9.5,
  ),
  const FundingOption(
    id: 'f3', name: 'PMEGP — Manufacturing Segment', provider: 'KVIC / Govt. of India',
    type: 'Government Subsidy', description: '15–35% capital subsidy for setting up manufacturing units including brick kilns, RMC plants.',
    eligibility: '8th pass, 18+ years, No existing enterprise', duration: '5–7 years',
    minAmount: 100000, maxAmount: 2500000, interestRate: 11.0,
  ),
  const FundingOption(
    id: 'f4', name: 'CGTMSE — Collateral Free Loan', provider: 'SIDBI / Govt. of India',
    type: 'Government Guarantee Scheme', description: 'Credit guarantee for collateral-free loans to MSMEs in construction supply chain.',
    eligibility: 'Registered MSME with good credit score', duration: '5–10 years',
    minAmount: 500000, maxAmount: 20000000, interestRate: 10.25,
  ),
  const FundingOption(
    id: 'f5', name: 'SBI Construction Equipment Loan', provider: 'State Bank of India',
    type: 'Bank Loan', description: 'Term loan for purchase of construction equipment — JCB, Mixer, Transit Mixer, etc.',
    eligibility: 'Contractor with 2+ years experience, good CIBIL', duration: '3–7 years',
    minAmount: 500000, maxAmount: 50000000, interestRate: 9.5,
  ),
  const FundingOption(
    id: 'f6', name: 'HDFC Self Construction Home Loan', provider: 'HDFC Bank',
    type: 'Bank Loan', description: 'Home construction loan disbursed in stages as construction progresses.',
    eligibility: 'Plot owner with approved building plan, income proof', duration: 'Up to 30 years',
    minAmount: 1000000, maxAmount: 100000000, interestRate: 8.75,
  ),
  const FundingOption(
    id: 'f7', name: 'ICICI Bank Business Loan', provider: 'ICICI Bank',
    type: 'Bank Loan', description: 'Unsecured business loans for contractors & suppliers with fast approval.',
    eligibility: 'Business turnover > ₹40L/year, 2+ years in business', duration: '1–5 years',
    minAmount: 100000, maxAmount: 20000000, interestRate: 10.75,
  ),
  const FundingOption(
    id: 'f8', name: 'Bajaj Finserv Business Loan', provider: 'Bajaj Finserv',
    type: 'NBFC / Private', description: 'Quick approval business loans with minimal documentation.',
    eligibility: 'GST registered business, ITR for 2 years', duration: '1–7 years',
    minAmount: 100000, maxAmount: 5000000, interestRate: 14.5,
  ),
];

// ─── Business Types ───────────────────────────────────────────────────────────

final List<BusinessType> mockBusinessTypes = [
  const BusinessType(
    id: 'b1', name: 'Construction Contractor', icon: Icons.construction,
    color: Color(0xFFE65100),
    description: 'Start a civil construction contracting firm. Take up residential, commercial, or government projects.',
    minInvestment: '₹5 Lakh', maxInvestment: '₹25 Lakh', returns: '15–30% margin per project',
    steps: [
      'Register as Proprietorship / Partnership / Pvt Ltd',
      'Get MSME/Udyam registration',
      'Obtain Contractor License from local municipality',
      'Open a current account & get GST number',
      'Get EPF & ESI registration for labour',
      'Build a portfolio with small projects',
      'Apply for Class-A/B/C contractor category',
    ],
    documents: ['Aadhaar & PAN', 'Business registration', 'GST certificate', 'Bank account proof', 'Contractor license'],
  ),
  const BusinessType(
    id: 'b2', name: 'Building Material Supply', icon: Icons.store,
    color: Color(0xFF1565C0),
    description: 'Open a construction material dealership or wholesale supply business for cement, steel, tiles, etc.',
    minInvestment: '₹10 Lakh', maxInvestment: '₹50 Lakh', returns: '8–15% margin on materials',
    steps: [
      'Register business (GST mandatory for >₹40L turnover)',
      'Secure dealership/agency from manufacturers',
      'Arrange godown/warehouse space',
      'Set up inventory management system',
      'Hire delivery vehicle or arrange transport',
      'Build customer base (contractors, builders)',
      'Offer credit terms to regular buyers',
    ],
    documents: ['GST registration', 'Shop & Establishment license', 'Godown lease', 'Trade license', 'FSSAI if applicable'],
  ),
  const BusinessType(
    id: 'b3', name: 'Manpower Agency', icon: Icons.people,
    color: Color(0xFF2E7D32),
    description: 'Build and supply skilled construction labour to contractors, builders, and property owners.',
    minInvestment: '₹2 Lakh', maxInvestment: '₹5 Lakh', returns: '10–15% on labour billing',
    steps: [
      'Register as Labour Contractor (Form V)',
      'Get Labour License from Labour Department',
      'Enrol workers under ESI & PF',
      'Create skill categories and rate cards',
      'Partner with training institutes for skilled workers',
      'Maintain a worker database with Aadhaar verification',
      'Market to builders, contractors, and corporates',
    ],
    documents: ['Labour license', 'ESI/EPF registration', 'Worker Aadhaar records', 'Bank account', 'MSME certificate'],
  ),
  const BusinessType(
    id: 'b4', name: 'Interior Design Firm', icon: Icons.design_services,
    color: Color(0xFF6A1B9A),
    description: 'Offer end-to-end interior design & execution services for residential and commercial spaces.',
    minInvestment: '₹3 Lakh', maxInvestment: '₹10 Lakh', returns: '20–35% project margin',
    steps: [
      'Get a degree or certification in Interior Design (or partner with a designer)',
      'Register business & get GST',
      'Build a portfolio (start with relatives/friends)',
      'Hire or empanel skilled workers (carpenters, painters, electricians)',
      'Create a 3D design setup (SketchUp / AutoCAD)',
      'List on design platforms (Urban Company, Houzz)',
      'Network with builders & real estate agents',
    ],
    documents: ['Design qualification certificate', 'GST registration', 'Business registration', 'Portfolio samples'],
  ),
];

// ─── Jobs ────────────────────────────────────────────────────────────────────

final List<Job> mockJobs = [
  const Job(
    id: 'j1', title: 'Junior Civil Engineer', company: 'Prestige Constructions Pvt Ltd',
    location: 'Bengaluru', jobType: 'Full-time', minSalary: '₹25,000', maxSalary: '₹35,000',
    deadline: '31 May 2026',
    description: 'Monitor site activities, coordinate with contractors, prepare daily progress reports.',
    requirements: ['B.E / B.Tech Civil Engineering', '0–2 years experience', 'AutoCAD knowledge', 'Good communication'],
  ),
  const Job(
    id: 'j2', title: 'Site Supervisor', company: 'Brigade Group',
    location: 'Hyderabad', jobType: 'Full-time', minSalary: '₹22,000', maxSalary: '₹30,000',
    deadline: '20 May 2026',
    description: 'Supervise daily construction activities, manage 50+ labourers, ensure quality & safety.',
    requirements: ['Diploma in Civil / ITI', '5+ years site experience', 'Leadership skills', 'Quality control knowledge'],
  ),
  const Job(
    id: 'j3', title: 'Quantity Surveyor', company: 'Shapoorji Pallonji Group',
    location: 'Mumbai', jobType: 'Full-time', minSalary: '₹35,000', maxSalary: '₹50,000',
    deadline: '15 Jun 2026',
    description: 'Prepare BOQ, rate analysis, billing, and cost control for large infrastructure projects.',
    requirements: ['B.E Civil / B.Sc QS', '3–5 years QS experience', 'MS Excel expertise', 'BOQ preparation skills'],
  ),
  const Job(
    id: 'j4', title: 'AutoCAD Draftsman (Civil)', company: 'Design Build Associates',
    location: 'Chennai', jobType: 'Full-time', minSalary: '₹18,000', maxSalary: '₹25,000',
    deadline: '10 Jun 2026',
    description: 'Prepare 2D architectural & structural drawings using AutoCAD for residential projects.',
    requirements: ['Diploma Civil / AutoCAD certification', '1–3 years experience', 'AutoCAD 2D proficiency'],
  ),
  const Job(
    id: 'j5', title: 'Project Manager — Civil', company: 'L&T Construction',
    location: 'Delhi NCR', jobType: 'Full-time', minSalary: '₹80,000', maxSalary: '₹1,20,000',
    deadline: '30 Jun 2026',
    description: 'Lead a team of 200+ on a metro rail infrastructure project. P&L responsibility.',
    requirements: ['B.E Civil + MBA preferred', '12+ years experience', 'PMP certification', 'Large project experience'],
  ),
  const Job(
    id: 'j6', title: 'Safety Officer (HSE)', company: 'NCC Ltd',
    location: 'Pune', jobType: 'Full-time', minSalary: '₹28,000', maxSalary: '₹42,000',
    deadline: '25 May 2026',
    description: 'Implement safety protocols, conduct toolbox talks, monitor PPE compliance on site.',
    requirements: ['Diploma + NEBOSH / IOSH certification', '3+ years HSE experience', 'First Aid certified'],
  ),
  const Job(
    id: 'j7', title: 'MEP Engineer', company: 'Cushman & Wakefield',
    location: 'Bengaluru', jobType: 'Full-time', minSalary: '₹40,000', maxSalary: '₹60,000',
    deadline: '20 Jun 2026',
    description: 'Design and supervise MEP (Mechanical, Electrical, Plumbing) works for commercial buildings.',
    requirements: ['B.E Mechanical / Electrical', '4+ years MEP experience', 'AutoCAD MEP / Revit MEP'],
  ),
  const Job(
    id: 'j8', title: 'Site Engineer (Contracts)', company: 'Tata Projects Ltd',
    location: 'Coimbatore', jobType: 'Contract (1 year)', minSalary: '₹30,000', maxSalary: '₹40,000',
    deadline: '15 May 2026',
    description: 'Execute civil works as per drawings, manage subcontractors and daily reporting.',
    requirements: ['B.E Civil', '2–4 years experience', 'Willingness to relocate'],
  ),
];

// ─── Training Courses ─────────────────────────────────────────────────────────

final List<TrainingCourse> mockCourses = [
  const TrainingCourse(
    id: 'c1', name: 'Masonry & Construction', provider: 'NSDC (National Skill Dev. Corp.)',
    duration: '3 Months', certification: 'NSQF Level 3 Certificate', fee: 3500,
    mode: 'Offline — Bengaluru, Chennai, Hyderabad',
    description: 'Bricklaying, plastering, concreting basics. Practical site training included.',
  ),
  const TrainingCourse(
    id: 'c2', name: 'Plumbing Technology', provider: 'ITI / CITS',
    duration: '2 Months', certification: 'NCVT Certificate', fee: 4000,
    mode: 'Offline — All major cities',
    description: 'CPVC/PPR fitting, sanitary installation, drainage system design and maintenance.',
  ),
  const TrainingCourse(
    id: 'c3', name: 'Electrical Wiring & Installation', provider: 'ITI / CITS',
    duration: '3 Months', certification: 'NCVT Diploma + Wireman License', fee: 5000,
    mode: 'Offline — Pan India ITI centres',
    description: 'Domestic & industrial wiring, switchboard fitting, MCB panel, energy meter connection.',
  ),
  const TrainingCourse(
    id: 'c4', name: 'Floor & Wall Tiling', provider: 'NSDC / Skill India',
    duration: '6 Weeks', certification: 'NSQF Level 3 Certificate', fee: 2500,
    mode: 'Offline — Bengaluru, Mumbai, Delhi',
    description: 'Floor tile laying, wall cladding, grouting, levelling, waterproofing techniques.',
  ),
  const TrainingCourse(
    id: 'c5', name: 'AutoCAD for Civil Engineers', provider: 'CADD Centre',
    duration: '2 Months', certification: 'AutoCAD Professional Certificate', fee: 8000,
    mode: 'Online + Offline',
    description: '2D drafting, floor plan, elevation, section, site plan. Industry projects practice.',
  ),
  const TrainingCourse(
    id: 'c6', name: 'Interior Design Foundation', provider: 'NIFT / Private Institutes',
    duration: '3 Months', certification: 'Interior Design Diploma', fee: 15000,
    mode: 'Offline — Metro cities',
    description: 'Space planning, colour theory, furniture layout, 3D visualization using SketchUp.',
  ),
  const TrainingCourse(
    id: 'c7', name: 'Quantity Surveying & Estimation', provider: 'NICMAR Online',
    duration: '6 Weeks', certification: 'QS Certificate — NICMAR', fee: 9500,
    mode: 'Online (live + recorded)',
    description: 'BOQ preparation, rate analysis, contract management, tender documents basics.',
  ),
  const TrainingCourse(
    id: 'c8', name: 'Construction Safety (HSE)', provider: 'NEBOSH / IOSH Approved',
    duration: '1 Month', certification: 'IOSH Working Safely Certificate', fee: 6000,
    mode: 'Online',
    description: 'Site hazards, PPE usage, risk assessment, emergency procedures, toolbox talks.',
  ),
];

// ─── Area Contacts – Assam Districts ─────────────────────────────────────────

final List<AreaContact> mockAreaContacts = [
  // Upper Assam
  const AreaContact(district: 'Dibrugarh', region: 'Upper Assam', name: 'Biren Gogoi', designation: 'District Manager', phone: '9876012340'),
  const AreaContact(district: 'Tinsukia', region: 'Upper Assam', name: 'Ranjit Phukan', designation: 'Area Coordinator', phone: '9435112341'),
  const AreaContact(district: 'Sivasagar', region: 'Upper Assam', name: 'Dipankar Saikia', designation: 'District Incharge', phone: '9707212342'),
  const AreaContact(district: 'Charaideo', region: 'Upper Assam', name: 'Hemanta Konwar', designation: 'Area Representative', phone: '6901312343'),
  const AreaContact(district: 'Jorhat', region: 'Upper Assam', name: 'Rajib Bora', designation: 'District Manager', phone: '9954412344'),
  const AreaContact(district: 'Golaghat', region: 'Upper Assam', name: 'Tarun Buragohain', designation: 'Area Coordinator', phone: '8011512345'),
  const AreaContact(district: 'Dhemaji', region: 'Upper Assam', name: 'Pankaj Moran', designation: 'District Incharge', phone: '7896612346'),
  const AreaContact(district: 'Lakhimpur', region: 'Upper Assam', name: 'Nilutpal Pegu', designation: 'Area Manager', phone: '9365712347'),
  const AreaContact(district: 'Majuli', region: 'Upper Assam', name: 'Pradip Payeng', designation: 'District Representative', phone: '9085812348'),
  const AreaContact(district: 'Biswanath', region: 'Upper Assam', name: 'Sanjeev Kalita', designation: 'Area Coordinator', phone: '6003912349'),

  // Lower Assam
  const AreaContact(district: 'Kamrup (Rural)', region: 'Lower Assam', name: 'Jyotish Das', designation: 'District Manager', phone: '9864023350'),
  const AreaContact(district: 'Kamrup Metro', region: 'Lower Assam', name: 'Bijit Sharma', designation: 'City Manager', phone: '9435123351'),
  const AreaContact(district: 'Barpeta', region: 'Lower Assam', name: 'Kamal Nath', designation: 'District Coordinator', phone: '9706223352'),
  const AreaContact(district: 'Nalbari', region: 'Lower Assam', name: 'Binod Deka', designation: 'Area Manager', phone: '8876323353'),
  const AreaContact(district: 'Bajali', region: 'Lower Assam', name: 'Chandan Goswami', designation: 'District Incharge', phone: '7896423354'),
  const AreaContact(district: 'Bongaigaon', region: 'Lower Assam', name: 'Subhash Boro', designation: 'Area Representative', phone: '9954523355'),
  const AreaContact(district: 'Dhubri', region: 'Lower Assam', name: 'Dilip Ahmed', designation: 'District Manager', phone: '6001623356'),
  const AreaContact(district: 'Goalpara', region: 'Lower Assam', name: 'Rupam Koch', designation: 'Area Coordinator', phone: '9365723357'),
  const AreaContact(district: 'South Salmara', region: 'Lower Assam', name: 'Jiten Ali', designation: 'District Incharge', phone: '8011823358'),
  const AreaContact(district: 'Kokrajhar', region: 'Lower Assam', name: 'Sanjay Basumatary', designation: 'Area Manager', phone: '9707923359'),
  const AreaContact(district: 'Chirang', region: 'Lower Assam', name: 'Bhargab Brahma', designation: 'District Coordinator', phone: '9085023360'),

  // Central Assam
  const AreaContact(district: 'Nagaon', region: 'Central Assam', name: 'Manash Hazarika', designation: 'Regional Manager', phone: '9864034461'),
  const AreaContact(district: 'Morigaon', region: 'Central Assam', name: 'Kishore Kakati', designation: 'District Manager', phone: '9435134462'),
  const AreaContact(district: 'Hojai', region: 'Central Assam', name: 'Palash Islam', designation: 'Area Coordinator', phone: '8876234463'),

  // North Assam
  const AreaContact(district: 'Darrang', region: 'North Assam', name: 'Robin Mahanta', designation: 'District Manager', phone: '9954045574'),
  const AreaContact(district: 'Sonitpur', region: 'North Assam', name: 'Debajit Choudhury', designation: 'Area Coordinator', phone: '9707145575'),
  const AreaContact(district: 'Udalguri', region: 'North Assam', name: 'Simanta Rabha', designation: 'District Incharge', phone: '6001245576'),
  const AreaContact(district: 'Tamulpur', region: 'North Assam', name: 'Uday Nath', designation: 'Area Representative', phone: '9365345577'),
  const AreaContact(district: 'Baksa', region: 'North Assam', name: 'Pulak Baruah', designation: 'District Manager', phone: '8011445578'),

  // Barak Valley
  const AreaContact(district: 'Cachar', region: 'Barak Valley', name: 'Dhiraj Laskar', designation: 'Regional Manager', phone: '9864056689'),
  const AreaContact(district: 'Hailakandi', region: 'Barak Valley', name: 'Gaurav Roy', designation: 'District Coordinator', phone: '9435156690'),
  const AreaContact(district: 'Karimganj', region: 'Barak Valley', name: 'Nayan Dutta', designation: 'Area Manager', phone: '9706256691'),

  // Hills
  const AreaContact(district: 'Karbi Anglong', region: 'Hills', name: 'Parag Terang', designation: 'District Incharge', phone: '9954067792'),
  const AreaContact(district: 'West Karbi Anglong', region: 'Hills', name: 'Suresh Timung', designation: 'Area Manager', phone: '8876167793'),
  const AreaContact(district: 'Dima Hasao', region: 'Hills', name: 'Bikash Nunisa', designation: 'District Coordinator', phone: '7896267794'),
];
