plugins { kotlin("jvm") version "1.9.0"; application }
repositories { mavenCentral() }
dependencies { implementation("aws.sdk.kotlin:lightsail:1.0.0"); testImplementation(kotlin("test")) }
