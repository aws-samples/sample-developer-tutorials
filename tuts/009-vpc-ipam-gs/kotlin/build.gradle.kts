plugins { kotlin("jvm") version "1.9.0"; application }
repositories { mavenCentral() }
dependencies { implementation("aws.sdk.kotlin:ec2:1.0.0"); testImplementation(kotlin("test")) }
