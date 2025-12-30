# Firestore Collection Examples

This document contains example Firestore document structures for DevLokos app.

## Collections Overview

- `tutorials` - Tutorial metadata (YouTube videos)
- `courses` - Academy courses with modules and lessons
- `services` - Enterprise services offered
- `portfolio` - Portfolio projects/case studies
- `contact_submissions` - Contact form submissions

---

## 1. Tutorials Collection

**Collection:** `tutorials`

### Example Document:

```json
{
  "id": "tutorial_001",
  "videoId": "dQw4w9WgXcQ",
  "title": "Getting Started with SwiftUI",
  "description": "Learn the basics of SwiftUI and build your first iOS app",
  "thumbnailUrl": "https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg",
  "category": "Mobile",
  "techStack": ["SwiftUI", "iOS", "Swift"],
  "level": "Beginner",
  "relatedCourseId": "course_001",
  "duration": 1800,
  "publishedAt": "2024-01-15T10:00:00Z",
  "createdAt": "2024-01-10T10:00:00Z",
  "isPublished": true,
  "viewCount": 1250
}
```

### Fields:
- `videoId` (string, required): YouTube video ID
- `title` (string, required): Tutorial title
- `description` (string, required): Tutorial description
- `thumbnailUrl` (string, required): Thumbnail image URL
- `category` (string, required): One of: Backend, Frontend, Mobile, DevOps, AI, Databases
- `techStack` (array<string>, required): Array of technologies (e.g., ["SwiftUI", "Firebase"])
- `level` (string, required): One of: Beginner, Intermediate, Advanced
- `relatedCourseId` (string, optional): Link to Academy course
- `duration` (number, required): Duration in seconds
- `publishedAt` (timestamp, required): Publication date
- `createdAt` (timestamp, required): Creation date
- `isPublished` (boolean, default: true): Publication status
- `viewCount` (number, optional): View count

### Indexes Required:
- `isPublished` (ascending) + `publishedAt` (descending)
- `isPublished` (ascending) + `category` (ascending) + `publishedAt` (descending)
- `isPublished` (ascending) + `level` (ascending) + `publishedAt` (descending)
- `isPublished` (ascending) + `techStack` (array-contains) + `publishedAt` (descending)

---

## 2. Courses Collection

**Collection:** `courses`

### Example Document:

```json
{
  "id": "course_001",
  "title": "Complete iOS Development with SwiftUI",
  "description": "Master iOS development from scratch using SwiftUI and modern best practices",
  "learningObjectives": [
    "Build native iOS apps with SwiftUI",
    "Understand MVVM architecture",
    "Integrate Firebase for backend services",
    "Publish apps to the App Store"
  ],
  "difficulty": "Intermediate",
  "duration": 1200,
  "thumbnailUrl": "https://example.com/course-thumb.jpg",
  "learningPaths": ["Mobile"],
  "modules": [
    {
      "id": "module_001",
      "title": "Introduction to SwiftUI",
      "description": "Learn the fundamentals of SwiftUI",
      "order": 1,
      "lessons": [
        {
          "id": "lesson_001",
          "title": "SwiftUI Basics",
          "description": "Introduction to SwiftUI views and modifiers",
          "type": "video",
          "videoId": "dQw4w9WgXcQ",
          "order": 1,
          "duration": 30,
          "isPublished": true
        },
        {
          "id": "lesson_002",
          "title": "State Management",
          "description": "Understanding @State, @Binding, and @ObservedObject",
          "type": "text",
          "content": "# State Management\n\nSwiftUI provides several property wrappers...",
          "order": 2,
          "isPublished": true
        }
      ]
    }
  ],
  "finalProjectId": "project_001",
  "isPublished": true,
  "isPaid": false,
  "price": null,
  "createdAt": "2024-01-01T10:00:00Z",
  "updatedAt": "2024-01-15T10:00:00Z",
  "publishedAt": "2024-01-15T10:00:00Z",
  "enrollmentCount": 250
}
```

### Fields:
- `title` (string, required): Course title
- `description` (string, required): Course description
- `learningObjectives` (array<string>, required): List of learning objectives
- `difficulty` (string, required): One of: Beginner, Intermediate, Advanced
- `duration` (number, required): Total duration in minutes
- `thumbnailUrl` (string, optional): Course thumbnail URL
- `learningPaths` (array<string>, required): Array of learning paths (e.g., ["Mobile", "Backend"])
- `modules` (array<object>, required): Array of course modules
- `finalProjectId` (string, optional): Reference to final project
- `isPublished` (boolean, default: false): Publication status
- `isPaid` (boolean, default: false): Whether course is paid
- `price` (number, optional): Price in USD (for paid courses)
- `createdAt` (timestamp, required): Creation date
- `updatedAt` (timestamp, required): Last update date
- `publishedAt` (timestamp, optional): Publication date
- `enrollmentCount` (number, optional): Number of enrolled students

### Module Structure:
- `id` (string, required): Module ID
- `title` (string, required): Module title
- `description` (string, required): Module description
- `order` (number, required): Display order
- `lessons` (array<object>, required): Array of lessons

### Lesson Structure:
- `id` (string, required): Lesson ID
- `title` (string, required): Lesson title
- `description` (string, required): Lesson description
- `type` (string, required): One of: "video", "text", "external"
- `videoId` (string, optional): YouTube video ID (if type is "video")
- `content` (string, optional): Text content (if type is "text")
- `externalUrl` (string, optional): External resource URL (if type is "external")
- `order` (number, required): Display order within module
- `duration` (number, optional): Duration in minutes (for video lessons)
- `isPublished` (boolean, default: true): Publication status

### Indexes Required:
- `isPublished` (ascending) + `publishedAt` (descending)
- `isPublished` (ascending) + `learningPaths` (array-contains) + `publishedAt` (descending)
- `isPublished` (ascending) + `difficulty` (ascending) + `publishedAt` (descending)

---

## 3. Services Collection

**Collection:** `services`

### Example Document:

```json
{
  "id": "service_001",
  "title": "Custom Software Development",
  "description": "We build custom software solutions tailored to your business needs",
  "icon": "💻",
  "features": [
    "Full-stack development",
    "Agile methodology",
    "Continuous integration",
    "Post-launch support"
  ],
  "order": 1,
  "isPublished": true
}
```

### Fields:
- `title` (string, required): Service title
- `description` (string, required): Service description
- `icon` (string, required): Icon emoji or icon name
- `features` (array<string>, required): List of service features
- `order` (number, required): Display order
- `isPublished` (boolean, default: true): Publication status

### Indexes Required:
- `isPublished` (ascending) + `order` (ascending)

---

## 4. Portfolio Collection

**Collection:** `portfolio`

### Example Document:

```json
{
  "id": "portfolio_001",
  "title": "E-Commerce Mobile App",
  "description": "Native iOS and Android e-commerce app with real-time inventory management",
  "thumbnailUrl": "https://example.com/portfolio-thumb.jpg",
  "technologies": ["SwiftUI", "Kotlin", "Firebase", "Stripe"],
  "category": "Mobile",
  "projectUrl": "https://example.com/project",
  "caseStudyUrl": "https://example.com/case-study",
  "createdAt": "2024-01-10T10:00:00Z",
  "isPublished": true,
  "order": 1
}
```

### Fields:
- `title` (string, required): Project title
- `description` (string, required): Project description
- `thumbnailUrl` (string, optional): Project thumbnail URL
- `technologies` (array<string>, required): Technologies used
- `category` (string, required): Project category (e.g., "Mobile", "Web", "Backend")
- `projectUrl` (string, optional): Link to live project
- `caseStudyUrl` (string, optional): Link to detailed case study
- `createdAt` (timestamp, required): Creation date
- `isPublished` (boolean, default: true): Publication status
- `order` (number, required): Display order

### Indexes Required:
- `isPublished` (ascending) + `order` (ascending)

---

## 5. Contact Submissions Collection

**Collection:** `contact_submissions`

### Example Document:

```json
{
  "id": "submission_001",
  "name": "John Doe",
  "email": "john@example.com",
  "company": "Acme Corp",
  "message": "We're looking for a custom mobile app for our business",
  "projectType": "Custom Software Development",
  "submittedAt": "2024-01-20T14:30:00Z",
  "isProcessed": false,
  "notes": null
}
```

### Fields:
- `name` (string, required): Contact name
- `email` (string, required): Contact email
- `company` (string, optional): Company name
- `message` (string, required): Contact message
- `projectType` (string, optional): Type of project
- `submittedAt` (timestamp, required): Submission timestamp
- `isProcessed` (boolean, default: false): Whether submission has been processed
- `notes` (string, optional): Admin notes

### Indexes Required:
- `submittedAt` (descending)
- `isProcessed` (ascending) + `submittedAt` (descending)

---

## Firestore Security Rules

Update your `firestore.rules` to include:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Existing user rules...
    
    // Tutorials - read for authenticated users
    match /tutorials/{tutorialId} {
      allow read: if request.auth != null;
      allow write: if false; // Only via admin/backend
    }
    
    // Courses - read for authenticated users
    match /courses/{courseId} {
      allow read: if request.auth != null;
      allow write: if false; // Only via admin/backend
    }
    
    // Services - read for authenticated users
    match /services/{serviceId} {
      allow read: if request.auth != null;
      allow write: if false; // Only via admin/backend
    }
    
    // Portfolio - read for authenticated users
    match /portfolio/{projectId} {
      allow read: if request.auth != null;
      allow write: if false; // Only via admin/backend
    }
    
    // Contact submissions - write for authenticated users, read only for admins
    match /contact_submissions/{submissionId} {
      allow create: if request.auth != null;
      allow read: if false; // Only via admin/backend
      allow update: if false; // Only via admin/backend
    }
  }
}
```

---

## Cloud Function for Contact Form

Create a Cloud Function to handle contact form submissions:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.onContactSubmission = functions.firestore
  .document('contact_submissions/{submissionId}')
  .onCreate(async (snap, context) => {
    const submission = snap.data();
    
    // Send email notification (using SendGrid, Mailgun, etc.)
    // Or send to Slack webhook
    
    console.log('New contact submission:', submission);
    
    return null;
  });
```

---

## Notes

1. **Timestamps**: Use Firestore `Timestamp` type for all date fields
2. **Arrays**: Use Firestore arrays for `techStack`, `learningPaths`, `features`, etc.
3. **Nested Objects**: Modules and lessons are stored as nested arrays within course documents
4. **Indexes**: Create composite indexes in Firestore Console for efficient queries
5. **Security**: All collections require authentication for reads; writes are admin-only except contact submissions


