package msr.mirudl.app;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;

public class DeveloperActivity extends BaseActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_developer);

        // Back button
        findViewById(R.id.btn_back).setOnClickListener(v -> finish());

        // GitHub link
        findViewById(R.id.dev_github).setOnClickListener(v -> {
            try {
                startActivity(new Intent(Intent.ACTION_VIEW,
                        Uri.parse("https://github.com/Snip3rMask")));
            } catch (Exception ignored) {}
        });

        // Email / Contact
        findViewById(R.id.dev_email).setOnClickListener(v -> {
            try {
                Intent email = new Intent(Intent.ACTION_SENDTO);
                email.setData(Uri.parse("mailto:msrofficial@email.com"));
                startActivity(email);
            } catch (Exception ignored) {}
        });
    }
}
