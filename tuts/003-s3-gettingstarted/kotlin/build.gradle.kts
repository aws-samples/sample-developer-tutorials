plugins { kotlin("jvm") version "1.9.0"; application }
repositories { mavenCentral() }
dependencies { implementation("aws.sdk.kotlin:s3:1.0.0"); testImplementation(kotlin("test")) }
